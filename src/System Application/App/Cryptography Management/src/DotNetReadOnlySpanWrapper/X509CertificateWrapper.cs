using System;
using System.Security.Cryptography.X509Certificates;
using System.Runtime.Versioning;

namespace X509CertificateWrapper
{
    public class X509CertificateWrapper
    {
        public static string CreateBase64FromPem(string certPem, string keyPem, string password)
        {
            return Convert.ToBase64String(X509Certificate2.CreateFromPem(certPem, keyPem).Export(X509ContentType.Pkcs12, password));
        }
    }
}