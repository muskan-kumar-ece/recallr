import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { createHash, randomUUID } from 'node:crypto';

export const cardFieldLimits: Record<string, number> = {
  name: 200, role: 200, company: 200, bio: 1000, email: 200, phone: 200,
  whatsapp: 200, location: 200, website: 2000, linkedin: 2000,
  services: 1000, photoUrl: 2000,
};
function uid(request: any): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in to save to your network.');
  return request.auth.uid;
}
function text(value: unknown, max: number, required = false): string {
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) {
    throw new HttpsError('invalid-argument', 'A field is missing or too long.');
  }
  return value.trim();
}
function id(value: unknown): string {
  const result = text(value, 128, true);
  if (!/^[a-zA-Z0-9_-]+$/.test(result)) throw new HttpsError('invalid-argument', 'Invalid identifier.');
  return result;
}
function categories(value: unknown): string[] {
  if (!Array.isArray(value) || value.length > 20) throw new HttpsError('invalid-argument', 'Choose up to 20 categories.');
  return [...new Set(value.map(id))];
}

export function publicCardFields(fields: any, visible: unknown): Record<string, string> {
  if (!fields || typeof fields !== 'object' || !Array.isArray(visible)) throw new HttpsError('invalid-argument', 'Invalid card.');
  const result: Record<string, string> = {};
  for (const [key, max] of Object.entries(cardFieldLimits)) {
    const value = text(fields[key] ?? '', max, key === 'name');
    if (['website', 'linkedin', 'photoUrl'].includes(key) && value) {
      try { if (new URL(value).protocol !== 'https:') throw new Error(); }
      catch { throw new HttpsError('invalid-argument', 'Links must be valid HTTPS URLs.'); }
    }
    if (value && (key === 'name' || visible.includes(key))) result[key] = value;
  }
  return result;
}

export const saveNetworkCategory = onCall(async request => {
  const userId = uid(request);
  const data = request.data || {};
  const name = text(data.name, 60, true);
  const categoryId = data.id ? id(data.id) : randomUUID();
  const db = getFirestore();
  const user = db.collection('users').doc(userId);
  const ref = user.collection('categories').doc(categoryId);
  const normalizedName = name.toLocaleLowerCase('en-US');
  const key = createHash('sha256').update(normalizedName).digest('hex');
  const nameRef = user.collection('category_names').doc(key);
  const icon = ['folder', 'work', 'people', 'school', 'favorite', 'event'].includes(data.icon) ? data.icon : 'folder';
  const color = Number.isInteger(data.color) && data.color >= 0 && data.color <= 0xffffffff ? data.color : 0xff7c3aed;
  await db.runTransaction(async tx => {
    const [existing, reserved] = await Promise.all([tx.get(ref), tx.get(nameRef)]);
    if (reserved.exists && reserved.data()?.id !== categoryId) throw new HttpsError('already-exists', 'A category with this name already exists.');
    const previousKey = existing.data()?.nameKey;
    if (previousKey && previousKey !== key) tx.delete(user.collection('category_names').doc(previousKey));
    tx.set(nameRef, {id: categoryId});
    tx.set(ref, {name, normalizedName, nameKey: key, icon, color,
      order: Number.isInteger(data.order) ? Math.max(0, Math.min(data.order, 10000)) : 0,
      updatedAt: FieldValue.serverTimestamp()});
  });
  return {id: categoryId};
});

export const deleteNetworkCategory = onCall(async request => {
  const user = getFirestore().collection('users').doc(uid(request));
  const categoryId = id(request.data?.id);
  const ref = user.collection('categories').doc(categoryId);
  // Mark first: concurrent assignments must reject a deleting category.
  const doc = await ref.get();
  if (!doc.exists) return {success: true};
  await ref.update({deleting: true});
  for (const collection of ['people', 'captures', 'follow_ups']) {
    while (true) {
      const page = await user.collection(collection).where('categoryIds', 'array-contains', categoryId).limit(400).get();
      if (page.empty) break;
      const batch = getFirestore().batch();
      page.docs.forEach(d => batch.update(d.ref, {categoryIds: FieldValue.arrayRemove(categoryId)}));
      await batch.commit();
    }
  }
  await getFirestore().runTransaction(async tx => {
    const latest = await tx.get(ref);
    if (latest.data()?.nameKey) tx.delete(user.collection('category_names').doc(latest.data()!.nameKey));
    tx.delete(ref);
  });
  return {success: true};
});

export const categorizeNetworkItem = onCall(async request => {
  const user = getFirestore().collection('users').doc(uid(request));
  const collection = request.data?.collection;
  if (!['people', 'captures', 'follow_ups'].includes(collection)) throw new HttpsError('invalid-argument', 'Invalid item type.');
  const categoryIds = categories(request.data?.categoryIds);
  const ref = user.collection(collection).doc(id(request.data?.id));
  await getFirestore().runTransaction(async tx => {
    const item = await tx.get(ref);
    const docs = await Promise.all(categoryIds.map(c => tx.get(user.collection('categories').doc(c))));
    if (!item.exists) throw new HttpsError('not-found', 'Item no longer exists.');
    if (docs.some(d => !d.exists || d.data()?.deleting)) throw new HttpsError('not-found', 'A selected category no longer exists.');
    tx.update(ref, {categoryIds, updatedAt: FieldValue.serverTimestamp()});
  });
  return {success: true};
});

export const publishVisitingCard = onCall(async request => {
  const userId = uid(request);
  const draftRef = getFirestore().collection('users').doc(userId).collection('card_drafts').doc(id(request.data?.draftId));
  return getFirestore().runTransaction(async tx => {
    const draft = await tx.get(draftRef);
    if (!draft.exists) throw new HttpsError('not-found', 'Save your draft first.');
    const data = draft.data()!;
    const fields = publicCardFields(data.fields, data.visibleFields);
    const cardId = data.publicId || randomUUID();
    const version = (data.version || 0) + 1;
    const accent = Number.isInteger(data.accent) && data.accent >= 0 && data.accent <= 0xffffffff ? data.accent : 0xff7c3aed;
    tx.set(getFirestore().collection('public_cards').doc(cardId), {
      fields, layout: data.layout === 'centered' ? 'centered' : 'classic', accent,
      published: true, version, updatedAt: FieldValue.serverTimestamp(),
      sharedBy: data.sourcePersonId ? text(request.auth?.token.name || 'Recallr member', 200) : null,
    });
    tx.set(getFirestore().collection('card_owners').doc(cardId), {userId, draftId: draft.id});
    tx.update(draftRef, {publicId: cardId, published: true, version});
    return {id: cardId, version};
  });
});

export const unpublishVisitingCard = onCall(async request => {
  const ref = getFirestore().collection('users').doc(uid(request)).collection('card_drafts').doc(id(request.data?.draftId));
  await getFirestore().runTransaction(async tx => {
    const draft = await tx.get(ref);
    if (!draft.exists) return;
    if (draft.data()?.publicId) tx.delete(getFirestore().collection('public_cards').doc(draft.data()!.publicId));
    tx.update(ref, {published: false});
  });
  return {success: true};
});

export const importVisitingCard = onCall(async request => {
  const user = getFirestore().collection('users').doc(uid(request));
  const cardId = id(request.data?.cardId);
  const categoryIds = categories(request.data?.categoryIds);
  const note = text(request.data?.note ?? '', 2000);
  const link = user.collection('card_imports').doc(cardId);
  return getFirestore().runTransaction(async tx => {
    const card = await tx.get(getFirestore().collection('public_cards').doc(cardId));
    const imported = await tx.get(link);
    if (!card.exists) throw new HttpsError('not-found', 'This card is no longer published.');
    const categoryDocs = await Promise.all(categoryIds.map(c => tx.get(user.collection('categories').doc(c))));
    if (categoryDocs.some(d => !d.exists || d.data()?.deleting)) throw new HttpsError('not-found', 'A category no longer exists.');
    const fields = card.data()!.fields as Record<string, string>;
    const people = user.collection('people');
    let personId = imported.data()?.personId as string | undefined;
    if (!personId && fields.email) {
      const match = await tx.get(people.where('email', '==', fields.email.toLowerCase()).limit(1));
      personId = match.docs[0]?.id;
    }
    if (!personId && fields.phone) {
      const match = await tx.get(people.where('phone', '==', fields.phone).limit(1));
      personId = match.docs[0]?.id;
    }
    personId ??= `card_${cardId}`;
    const personRef = people.doc(personId);
    const existing = await tx.get(personRef);
    const updates: Record<string, any> = {categoryIds: FieldValue.arrayUnion(...categoryIds),
      sourceCardId: cardId, sourceCardVersion: card.data()!.version,
      updatedAt: FieldValue.serverTimestamp()};
    if (!existing.exists) Object.assign(updates, {
      id: personId, userId: user.id, name: fields.name, role: fields.role || '', company: fields.company || '',
      email: fields.email?.toLowerCase() || null, phone: fields.phone || null,
      location: fields.location || '', locationOrEvent: fields.location || '',
      initials: fields.name.split(/\s+/).slice(0, 2).map(s => s[0]).join('').toUpperCase(),
      avatarUrl: fields.photoUrl || null, bio: fields.bio || '',
      createdAt: FieldValue.serverTimestamp(), interactionCount: 0,
    });
    // Keep local edits; add only previously missing contact details on re-import.
    else for (const key of ['email', 'phone', 'role', 'company']) {
      if (!existing.data()?.[key] && fields[key]) updates[key] = fields[key];
    }
    if (note) updates.privateNotes = FieldValue.arrayUnion(note);
    tx.set(personRef, updates, {merge: true});
    tx.set(link, {personId, version: card.data()!.version});
    return {personId, alreadySaved: existing.exists};
  });
});

export function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]!));
}
export function cardVcf(fields: Record<string, string>): string {
  const escape = (v: string) => v.replace(/\\/g, '\\\\').replace(/\r/g, '').replace(/\n/g, '\\n').replace(/;/g, '\\;').replace(/,/g, '\\,');
  return ['BEGIN:VCARD', 'VERSION:3.0', `FN:${escape(fields.name)}`,
    ...Object.entries({ORG: 'company', TITLE: 'role', TEL: 'phone', EMAIL: 'email', URL: 'website', NOTE: 'bio'})
      .filter(([, key]) => fields[key]).map(([key, field]) => `${key}:${escape(fields[field])}`),
    'END:VCARD', ''].join('\r\n');
}

export const publicVisitingCard = onRequest(async (req, res) => {
  res.set('Cache-Control', 'no-store');
  res.set('X-Content-Type-Options', 'nosniff');
  const cardId = req.path.split('/').filter(Boolean)[1];
  if (!cardId || !/^[a-zA-Z0-9_-]{1,128}$/.test(cardId)) { res.status(404).send('Card not found'); return; }
  try {
    const doc = await getFirestore().collection('public_cards').doc(cardId).get();
    if (!doc.exists || doc.data()?.published !== true) {
      res.status(404).send('This card is unavailable or has been unpublished.'); return;
    }
    const data = doc.data()!;
    const fields = data.fields as Record<string, string>;
    if (req.query.format === 'vcf') {
      res.set('Content-Disposition', 'attachment; filename="contact.vcf"');
      res.type('text/vcard').send(cardVcf(fields)); return;
    }
    const name = escapeHtml(fields.name);
    const bio = escapeHtml(fields.bio || [fields.role, fields.company].filter(Boolean).join(' · '));
    const accent = `#${(Number(data.accent) & 0xffffff).toString(16).padStart(6, '0')}`;
    const photo = fields.photoUrl ? `<img class="avatar" src="${escapeHtml(fields.photoUrl)}" alt="${name}"/>` : '';
    res.type('html').send(`<!doctype html><html lang="en"><head><meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1"><title>${name} · Recallr</title>
      <meta name="description" content="${bio}"><meta property="og:title" content="${name}">
      <meta property="og:description" content="${bio}"><meta property="og:type" content="profile">
      ${fields.photoUrl ? `<meta property="og:image" content="${escapeHtml(fields.photoUrl)}">` : ''}
      <style>:root{color-scheme:light dark;--accent:${accent}}*{box-sizing:border-box}body{margin:0;padding:32px 18px;font:16px/1.6 system-ui;background:light-dark(#f7f7fa,#09090b);color:light-dark(#18181b,#f5f5f7)}main{max-width:520px;margin:auto;padding:32px;border:1px solid var(--accent);border-radius:24px;background:light-dark(white,#18181b)}.avatar{width:96px;height:96px;object-fit:cover;border-radius:50%}h1{line-height:1.2;margin-bottom:8px}.role{color:var(--accent)}p{white-space:pre-wrap;overflow-wrap:anywhere}a{color:inherit;overflow-wrap:anywhere}.actions{display:flex;gap:12px;flex-wrap:wrap;margin-top:24px}.button{padding:12px 18px;border-radius:12px;text-decoration:none;border:1px solid var(--accent)}.primary{background:var(--accent);color:white}footer{font-size:12px;margin-top:32px;letter-spacing:1px}</style></head>
      <body><main>${photo}<h1>${name}</h1><p class="role">${escapeHtml([fields.role, fields.company].filter(Boolean).join(' · '))}</p>
      ${['bio', 'services', 'location'].filter(k => fields[k]).map(k => `<p>${escapeHtml(fields[k])}</p>`).join('')}
      <div class="actions"><a class="button primary" href="/save-card/${cardId}">Save to My Network</a>
      <a class="button" href="?format=vcf">Download Contact</a></div><div class="actions">
      ${fields.phone ? `<a href="tel:${encodeURIComponent(fields.phone)}">Call</a>` : ''}
      ${fields.email ? `<a href="mailto:${encodeURIComponent(fields.email)}">Email</a>` : ''}
      ${fields.whatsapp ? `<a href="https://wa.me/${fields.whatsapp.replace(/\D/g, '')}">WhatsApp</a>` : ''}
      ${['website', 'linkedin'].filter(k => fields[k]).map(k => `<a rel="noopener noreferrer" href="${escapeHtml(fields[k])}">${k === 'linkedin' ? 'LinkedIn' : 'Website'}</a>`).join('')}
      </div>${data.sharedBy ? `<p>Shared by ${escapeHtml(data.sharedBy)}</p>` : ''}<footer>RECALLR · DIGITAL VISITING CARD</footer></main></body></html>`);
  } catch { res.status(503).send('Could not load this card. Please try again.'); }
});
