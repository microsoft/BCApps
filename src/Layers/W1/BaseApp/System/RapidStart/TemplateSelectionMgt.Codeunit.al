namespace System.IO;

using System.Security.User;

codeunit 1900 "Template Selection Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure SaveCustTemplateSelectionForCurrentUser(TemplateCode: Code[10])
    begin
        SaveTemplateSelectionForCurrentUser(TemplateCode, GetCustomerTemplateSelectionCode());
    end;

    procedure GetLastCustTemplateSelection(var TemplateCode: Code[10]): Boolean
    begin
        exit(GetLastTemplateSelection(TemplateCode, GetCustomerTemplateSelectionCode()));
    end;

    procedure SaveVendorTemplateSelectionForCurrentUser(TemplateCode: Code[10])
    begin
        SaveTemplateSelectionForCurrentUser(TemplateCode, GetVendorTemplateSelectionCode());
    end;

    procedure GetLastVendorTemplateSelection(var TemplateCode: Code[10]): Boolean
    begin
        exit(GetLastTemplateSelection(TemplateCode, GetVendorTemplateSelectionCode()));
    end;

    procedure SaveItemTemplateSelectionForCurrentUser(TemplateCode: Code[10])
    begin
        SaveTemplateSelectionForCurrentUser(TemplateCode, GetItemTemplateSelectionCode());
    end;

    procedure GetLastItemTemplateSelection(var TemplateCode: Code[10]): Boolean
    begin
        exit(GetLastTemplateSelection(TemplateCode, GetItemTemplateSelectionCode()));
    end;

    procedure GetCustomerTemplateSelectionCode(): Code[20]
    begin
        exit('LASTCUSTTEMPSEL');
    end;

    procedure GetVendorTemplateSelectionCode(): Code[20]
    begin
        exit('LASTVENDTEMPSEL');
    end;

    procedure GetItemTemplateSelectionCode(): Code[20]
    begin
        exit('LASTITEMTEMPSEL');
    end;

    local procedure SaveTemplateSelectionForCurrentUser(TemplateCode: Code[10]; ContextCode: Code[20])
    var
        UserPreference: Record "User Preference";
    begin
        if UserPreference.Get(UserId, ContextCode) then
            UserPreference.Delete();

        UserPreference.Init();
        UserPreference."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserPreference."User ID"));
        UserPreference."Instruction Code" := ContextCode;
        UserPreference.SetUserSelection(TemplateCode);
        UserPreference.Insert();
    end;

    local procedure GetLastTemplateSelection(var TemplateCode: Code[10]; ContextCode: Code[20]): Boolean
    var
        UserPreference: Record "User Preference";
    begin
        if not UserPreference.Get(UserId, ContextCode) then
            exit(false);

        UserPreference.CalcFields("User Selection");
        TemplateCode := CopyStr(UserPreference.GetUserSelectionAsText(), 1, MaxStrLen(TemplateCode));
        exit(true);
    end;
}

