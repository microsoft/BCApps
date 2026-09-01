namespace System.Security.Encryption;

using System;

codeunit 3058 DotNet_AsymmetricAlgorithm
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetAsymmetricAlgorithm: DotNet AsymmetricAlgorithm;

    [Scope('OnPrem')]
    procedure FromXmlString(XmlString: Text)
    begin
        DotNetAsymmetricAlgorithm.FromXmlString(XmlString);
    end;

    [Scope('OnPrem')]
    procedure ToXmlString(IncludePrivateParameters: Boolean): Text
    begin
        exit(DotNetAsymmetricAlgorithm.ToXmlString(IncludePrivateParameters));
    end;

    [Scope('OnPrem')]
    procedure GetAsymmetricAlgorithm(var DotNetAsymmetricAlgorithm2: DotNet AsymmetricAlgorithm)
    begin
        DotNetAsymmetricAlgorithm2 := DotNetAsymmetricAlgorithm;
    end;

    [Scope('OnPrem')]
    procedure SetAsymmetricAlgorithm(DotNetAsymmetricAlgorithm2: DotNet AsymmetricAlgorithm)
    begin
        DotNetAsymmetricAlgorithm := DotNetAsymmetricAlgorithm2;
    end;
}