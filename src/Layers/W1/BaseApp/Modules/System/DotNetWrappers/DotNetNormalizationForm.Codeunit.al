namespace System.Text;

using System;

codeunit 3008 DotNet_NormalizationForm
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DotNetNormalizationForm: DotNet NormalizationForm;

    procedure FormC()
    begin
        DotNetNormalizationForm := DotNetNormalizationForm.FormC;
    end;

    procedure FormD()
    begin
        DotNetNormalizationForm := DotNetNormalizationForm.FormD;
    end;

    procedure FormKC()
    begin
        DotNetNormalizationForm := DotNetNormalizationForm.FormKC;
    end;

    procedure FormKD()
    begin
        DotNetNormalizationForm := DotNetNormalizationForm.FormKD;
    end;

    [Scope('OnPrem')]
    procedure GetNormalizationForm(var DotNetNormalizationForm2: DotNet NormalizationForm)
    begin
        DotNetNormalizationForm2 := DotNetNormalizationForm;
    end;

    [Scope('OnPrem')]
    procedure SetNormalizationForm(DotNetNormalizationForm2: DotNet NormalizationForm)
    begin
        DotNetNormalizationForm := DotNetNormalizationForm2;
    end;
}

