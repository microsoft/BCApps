codeunit 146043 "DotNet_X509Certificate2 Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [X509Certificate2]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestDemoCertificateFromBase64String()
    var
        TempBlob: Codeunit "Temp Blob";
        DotNet_MemoryStream: Codeunit DotNet_MemoryStream;
        DotNet_X509Certificate2: Codeunit DotNet_X509Certificate2;
        DotNet_Array: Codeunit DotNet_Array;
        DotNet_X509KeyStorageFlags: Codeunit DotNet_X509KeyStorageFlags;
        DotNet_X509ContentType: Codeunit DotNet_X509ContentType;
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        OutStr: OutStream;
        FriendlyName: Text;
        Thumbprint: Text;
        Issuer: Text;
        Subject: Text;
        Expiration: DateTime;
        HasPrivateKey: Boolean;
    begin
        // [SCENARIO] X509Certificate2 can be exported and imported into a blob and the certificate details are preserved
        // [GIVEN] A demo certificate
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(DemoCertificate(), OutStr);
        TempBlob.CreateInStream(InStr);
        DotNet_MemoryStream.MemoryStream();
        DotNet_MemoryStream.CopyFromInStream(InStr);
        DotNet_MemoryStream.ToArray(DotNet_Array);
        DotNet_X509KeyStorageFlags.Exportable();
        DotNet_X509Certificate2.X509Certificate2(DotNet_Array, '', DotNet_X509KeyStorageFlags); // Password not needed

        // [GIVEN] Certificate Details
        FriendlyName := DotNet_X509Certificate2.FriendlyName();
        Thumbprint := DotNet_X509Certificate2.Thumbprint();
        Issuer := DotNet_X509Certificate2.Issuer();
        Subject := DotNet_X509Certificate2.Subject();
        Expiration := DotNet_X509Certificate2.Expiration();
        HasPrivateKey := DotNet_X509Certificate2.HasPrivateKey();

        // [WHEN] Certificate Is exported and then imported
        DotNet_X509ContentType.Pkcs12();
        DotNet_X509Certificate2.Export(DotNet_X509ContentType, '', DotNet_Array);
        DotNet_MemoryStream.MemoryStream(DotNet_Array);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        DotNet_MemoryStream.WriteTo(OutStr);
        TempBlob.CreateInStream(InStr);
        DotNet_MemoryStream.MemoryStream();
        DotNet_MemoryStream.CopyFromInStream(InStr);
        DotNet_MemoryStream.ToArray(DotNet_Array);
        DotNet_X509KeyStorageFlags.Exportable();
        DotNet_X509Certificate2.X509Certificate2(DotNet_Array, '', DotNet_X509KeyStorageFlags); // Password not needed

        // [THEN] Certificate Details are preserved
        Assert.AreEqual(FriendlyName, DotNet_X509Certificate2.FriendlyName(), 'Certificate Details incorrect!');
        Assert.AreEqual(Thumbprint, DotNet_X509Certificate2.Thumbprint(), 'Certificate Details incorrect!');
        Assert.AreEqual(Issuer, DotNet_X509Certificate2.Issuer(), 'Certificate Details incorrect!');
        Assert.AreEqual(Subject, DotNet_X509Certificate2.Subject(), 'Certificate Details incorrect!');
        Assert.AreEqual(Expiration, DotNet_X509Certificate2.Expiration(), 'Certificate Details incorrect!');
        Assert.AreEqual(HasPrivateKey, DotNet_X509Certificate2.HasPrivateKey(), 'Certificate Details incorrect!');
    end;

    [Scope('OnPrem')]
    procedure DemoCertificate(): Text
    begin
        exit(
          'MIIM/QIBAzCCDLkGCSqGSIb3DQEHAaCCDKoEggymMIIMojCCBgsGCSqGSIb3DQEHAaCCBfwEggX4MIIF9DCCBfAGCyqGSIb3DQEM' +
          'CgECoIIE9jCCBPIwHAYKKoZIhvcNAQwBAzAOBAivq0/HTeszygICB9AEggTQizw8VPs6yzahoZiKKjB8Qwo0HHeYTKclP3NBon0l' +
          '0Kf5S69NT14MXFjqDoecdLV5l3C2Cwc3BugKdGXP+TRd7ECfOlHYWwsLkRrWtlbo/lCKoHwyemIbKkXENBANqcEtDmUsCGqdjRbY' +
          'Jfq+235O9K6R2jEvh07Q8UugC+6Z7TThxaWDYGUN4dZlPzZSOiPVun0DDuLRu7vJvDicb73ywBNtb2yy9qlD/FK2hI68eHtj0TDr' +
          'WHl6uieuCEC7IbZHvfDjRWHbYV4efUlUv+N5qqhSg8oFmvLs2bvqf2kQuzNXMNRk4P05V2ixr2oTwIW2+TCOxemvvv8mKqMJW60g' +
          '4KZtfKl6s/1RfO1Pv3nrDl0c0zI0A078TcfAC1zcrlZoUSD67K/1ovEpqQXljNVzm1385RlMyA40eBR7HhTxEiR4E0j4aeVfmJ3t' +
          'WPVGmeBGk4gxNhqmbHpsOO3XZp3WcEYG5tJIoI+ggW5FHRr6dMrsTaJjgpfaGcAN9AZCJoIysPdxPVciH4TsI1zA9l4FED8zdFk4' +
          's0kQU7ZGDQUIKI9cOghbtnqIE5SsHQWSsTZcVbMwwL9moehJXw/GmOz/T6K/98YxaFISjMw5yHdqZ6rz+7uKCINYh9SQMQSfatZJ' +
          'BYf1UehW3+Fvye/tG8Jah8x2byD7cB2rODBQItH79sWAo96CSOgcfc6o1eRZt82uHeoggTIxENzt0YxrJu6QeGbrmDcZU32pKBT6' +
          'HvCbzqxCDo7KK6YdmANPmbmryZscD5NaVBZLzN8V2rojoQA2nAnbLur7p5OWM87Dz+H70hdjy62gxtbOOT2xHYmdWbVKxOAGjWp+' +
          '/aR1BRT0WT6ipQI3rNrgR3Ak48ATmhzQ7K3c7g9AjuSMkWS+K6+PMvkhPpY7zWL20uKldt9qR7sWRfvknzPIsDAK0uje4zJjTu1H' +
          'ew5RBK+Y/DzNx8B2kqXYEDGfoVS6VbvfzPLJwP6c3GwV/OxWTj4fk2YlMr+ss3jTTPbAvQbpaYhcFrJ6m0c+Rb9loSZR3odB4Dzc' +
          'yLmnw4lNDXT7t3I/BcPtbboRkMLViecqlnZKQnb2pcC2hyDClWWkQxB2jNCRBhfQd/LLL9VRLlVzoOLIfLJw5oHVM5ZLlUjGJCID' +
          'owxL76QbftTvdFqu157e1f/uobTyKFRqZovI5h20feTiLwfx6SwrS1ZN5tpNnXg9bv2vTnlS7f9BuUBbJL6TkgoQRPEX628YJzfb' +
          'FAyoTAZnlQD7ILUZLik/9Gj0fD4bJ4hNO/rYi7FwX8LUkymCXElpq589+ikov3B+717f385x87kJ19NSqvxp4S5Vc6RFLHBEOx5z' +
          '8GbQeiegiJo/d4m9f1CxdnoL4GUqTKFAOsji1hKZ/VakhuRvUCslZLQMH3IK1WNUbQtJgh0XZ2Shr8P7bLVW0gOlnp84bUIW20nk' +
          'bqgIYoWldH6iHcZCWxQbjeYHMcEKj9MlxNuC1t0PvDR0WVInEuJhhOu6H0hPfZB4J+h74NXbOdbFIUlgRybu0c+QlEYuuyW3WbLL' +
          '4QzfwE+I55nIKRYDyo4j4QTBJ2YzTkOjDBVIOCnijiwSRqemkugCLQGNdSgJniQmnt2cYQpmK42kGysq2SC/bm2sgPMu3f7P4ARV' +
          'PEoxgeYwDQYJKwYBBAGCNxECMQAwEwYJKoZIhvcNAQkVMQYEBAEAAAAwWwYJKoZIhvcNAQkUMU4eTAB7AEQAOAA2ADAAMQA5ADEA' +
          'NwAtAEIAMgAxADQALQA0AEMANwBGAC0AQgBBADQARQAtADQAQwA0AEYAOAAyADAAQwBDAEMAQgA3AH0wYwYJKwYBBAGCNxEBMVYe' +
          'VABNAGkAYwByAG8AcwBvAGYAdAAgAEIAYQBzAGUAIABDAHIAeQBwAHQAbwBnAHIAYQBwAGgAaQBjACAAUAByAG8AdgBpAGQAZQBy' +
          'ACAAdgAxAC4AMDCCBo8GCSqGSIb3DQEHBqCCBoAwggZ8AgEAMIIGdQYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQMwDgQIlVUYGcm6' +
          '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' +
          '/luMBBSdPaTR4St9owOt4E6M2KbzawNCJAICB9A=');
    end;
}

