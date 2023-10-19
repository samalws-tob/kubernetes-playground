openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=abc Inc./CN=c.abc.com' -keyout c.abc.com.key -out c.abc.com.crt
