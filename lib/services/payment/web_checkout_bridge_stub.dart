/// Platform stub for non-web environments.
void openWebRazorpayCheckout({
  required String optionsJson,
  required void Function(String responseJson) onSuccess,
  required void Function(String error) onError,
}) {
  throw UnsupportedError('Web Razorpay checkout is only supported in web environments.');
}
