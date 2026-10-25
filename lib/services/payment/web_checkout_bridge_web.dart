import 'dart:js_interop';

@JS('openRazorpayWebCheckout')
external void _openRazorpayWebCheckout(
  JSString optionsJson,
  JSFunction successCallback,
  JSFunction errorCallback,
);

/// Web-specific implementation invoking window.openRazorpayWebCheckout.
void openWebRazorpayCheckout({
  required String optionsJson,
  required void Function(String responseJson) onSuccess,
  required void Function(String error) onError,
}) {
  final successCallback = ((JSString response) {
    onSuccess(response.toDart);
  }).toJS;

  final errorCallback = ((JSString error) {
    onError(error.toDart);
  }).toJS;

  _openRazorpayWebCheckout(
    optionsJson.toJS,
    successCallback,
    errorCallback,
  );
}
