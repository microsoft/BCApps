namespace Microsoft.Foundation.Company.Test;

using Microsoft.Foundation.Company;
using System.TestLibraries.Environment;

codeunit 139327 "Create Company Test Init"
{
    // Runs "Company-Initialize" inside a newly created company, in a background session started by
    // codeunit 139326 "Create Company Tests". The outcome is handed back through module-scoped isolated storage.

    trigger OnRun()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SaaSValue: Text;
    begin
        if IsolatedStorage.Get(GetSaaSKey(CompanyName()), DataScope::Module, SaaSValue) then
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(SaaSValue = Format(true, 0, 9));

        ClearLastError();
        if Codeunit.Run(Codeunit::"Company-Initialize") then
            SetResult(CompanyName(), GetSuccessValue())
        else
            SetResult(CompanyName(), CopyStr(GetLastErrorText() + ' ' + GetLastErrorCallStack(), 1, 8000));
    end;

    procedure SetRunAsSaaS(NewCompanyName: Text; RunAsSaaS: Boolean)
    begin
        IsolatedStorage.Set(GetSaaSKey(NewCompanyName), Format(RunAsSaaS, 0, 9), DataScope::Module);
    end;

    procedure TryGetResult(NewCompanyName: Text; var Result: Text): Boolean
    begin
        exit(IsolatedStorage.Get(GetResultKey(NewCompanyName), DataScope::Module, Result));
    end;

    procedure GetSuccessValue(): Text
    begin
        exit('OK');
    end;

    procedure ClearState(NewCompanyName: Text)
    begin
        if IsolatedStorage.Contains(GetSaaSKey(NewCompanyName), DataScope::Module) then
            IsolatedStorage.Delete(GetSaaSKey(NewCompanyName), DataScope::Module);
        if IsolatedStorage.Contains(GetResultKey(NewCompanyName), DataScope::Module) then
            IsolatedStorage.Delete(GetResultKey(NewCompanyName), DataScope::Module);
    end;

    local procedure SetResult(NewCompanyName: Text; Result: Text)
    begin
        IsolatedStorage.Set(GetResultKey(NewCompanyName), Result, DataScope::Module);
        Commit();
    end;

    local procedure GetSaaSKey(NewCompanyName: Text): Text
    begin
        exit('CreateCompanyTest_SaaS_' + NewCompanyName);
    end;

    local procedure GetResultKey(NewCompanyName: Text): Text
    begin
        exit('CreateCompanyTest_Result_' + NewCompanyName);
    end;
}
