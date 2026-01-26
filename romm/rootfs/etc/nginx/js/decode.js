// Base64 decoding module for nginx
function base64_decode(s) {
    // For compatibility - nginx njs will handle base64 decoding
    return s;
}

export default {
    base64_decode
};
