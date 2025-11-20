namespace System.Security.User;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;

codeunit 5700 "User Setup Management"
{
    Permissions = TableData Location = r,
                  TableData "Responsibility Center" = r;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        RespCenter: Record "Responsibility Center";
        CompanyInfo: Record "Company Information";
        UserLocation: Code[10];
        UserRespCenter: Code[10];
        SalesUserRespCenter: Code[10];
        PurchUserRespCenter: Code[10];
        ServUserRespCenter: Code[10];
        HasGotSalesUserSetup: Boolean;
        HasGotPurchUserSetup: Boolean;
        HasGotServUserSetup: Boolean;

        CustomerTxt: Label 'customer';
        VendorTxt: Label 'vendor';
#pragma warning disable AA0470
        RespCenterRelationMsg: Label 'This %1 is related to %2 %3. Your identification is setup to process from %2 %4.';
        ProcessedInRespCenterMsg: Label 'This document will be processed in your %2.';
#pragma warning restore AA0470
        AllowedDateErr: Label 'The date in the %1 field must not be after the date in the %2 field.', Comment = '%1 - caption Allow Posting From, %2 - caption Allow Posting To';
        AllowedPostingDateMsg: Label 'The setup of allowed posting dates is incorrect. The date in the %1 field must not be after the date in the %2 field.', Comment = '%1 - caption Allow Posting From, %2 - caption Allow Posting To';
        AllowedVATDateMsg: Label 'The setup of allowed VAT dates is incorrect. The date in the %1 field must not be after the date in the %2 field.', Comment = '%1 - caption Allow VAT Date From, %2 - caption Allow VAT Date To';
        OpenGLSetupActionTxt: Label 'Open the General Ledger Setup window';
        OpenUserSetupActionTxt: Label 'Open the User Setup window';
        PostingDateRangeErr: Label 'The Posting Date is not within your range of allowed posting dates.';

    procedure GetSalesFilter(): Code[10]
    begin
        exit(GetSalesFilter(UserId));
    end;

    procedure GetPurchasesFilter(): Code[10]
    begin
        exit(GetPurchasesFilter(UserId));
    end;

    procedure GetServiceFilter(): Code[10]
    begin
        exit(GetServiceFilter(UserId));
    end;

    procedure GetSalesFilter(UserCode: Code[50]) Result: Code[10]
    var
        IsHandled: Boolean;
    begin
        if not HasGotSalesUserSetup then begin
            IsHandled := false;
            OnBeforeGetSalesFilter(UserCode, UserLocation, SalesUserRespCenter, IsHandled);
            if IsHandled then
                exit(SalesUserRespCenter);

            CompanyInfo.Get();
            SalesUserRespCenter := CompanyInfo."Responsibility Center";
            UserLocation := CompanyInfo."Location Code";
            if UserSetup.Get(UserCode) and (UserCode <> '') then
                if UserSetup."Sales Resp. Ctr. Filter" <> '' then
                    SalesUserRespCenter := UserSetup."Sales Resp. Ctr. Filter";
            OnAfterGetSalesFilter(UserSetup, SalesUserRespCenter, UserLocation);
            HasGotSalesUserSetup := true;
        end;
        Result := SalesUserRespCenter;
        OnAfterGetSalesFilterProcedure(UserCode, Result);
    end;

    procedure GetPurchasesFilter(UserCode: Code[50]) Result: Code[10]
    begin
        if not HasGotPurchUserSetup then begin
            CompanyInfo.Get();
            PurchUserRespCenter := CompanyInfo."Responsibility Center";
            UserLocation := CompanyInfo."Location Code";
            if UserSetup.Get(UserCode) and (UserCode <> '') then
                if UserSetup."Purchase Resp. Ctr. Filter" <> '' then
                    PurchUserRespCenter := UserSetup."Purchase Resp. Ctr. Filter";
            OnAfterGetPurchFilter(UserSetup, PurchUserRespCenter, UserLocation);
            HasGotPurchUserSetup := true;
        end;
        Result := PurchUserRespCenter;
        OnAfterGetPurchasesFilter(UserCode, Result);
    end;

    procedure GetServiceFilter(UserCode: Code[50]) Result: Code[10]
    begin
        if not HasGotServUserSetup then begin
            CompanyInfo.Get();
            ServUserRespCenter := CompanyInfo."Responsibility Center";
            UserLocation := CompanyInfo."Location Code";
            if UserSetup.Get(UserCode) and (UserCode <> '') then
                if UserSetup."Service Resp. Ctr. Filter" <> '' then
                    ServUserRespCenter := UserSetup."Service Resp. Ctr. Filter";
            OnAfterGetServiceFilter(UserSetup, ServUserRespCenter, UserLocation);
            HasGotServUserSetup := true;
        end;
        Result := ServUserRespCenter;
        OnAfterGetServiceFilterProcedure(UserCode, Result);
    end;

    procedure GetRespCenter(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]): Code[10]
    var
        AccType: Text[50];
        IsHandled: Boolean;
    begin
        OnBeforeGetRespCenter(DocType, AccRespCenter, IsHandled, UserRespCenter);
        if IsHandled then
            exit(UserRespCenter);

        case DocType of
            DocType::Sales:
                begin
                    AccType := CustomerTxt;
                    UserRespCenter := GetSalesFilter();
                end;
            DocType::Purchase:
                begin
                    AccType := VendorTxt;
                    UserRespCenter := GetPurchasesFilter();
                end;
            DocType::Service:
                begin
                    AccType := CustomerTxt;
                    UserRespCenter := GetServiceFilter();
                end;
        end;
        if (AccRespCenter <> '') and
           (UserRespCenter <> '') and
           (AccRespCenter <> UserRespCenter)
        then
            Message(
              RespCenterRelationMsg +
              ProcessedInRespCenterMsg,
              AccType, RespCenter.TableCaption(), AccRespCenter, UserRespCenter);
        if UserRespCenter = '' then
            exit(AccRespCenter);

        exit(UserRespCenter);
    end;

    procedure CheckRespCenter(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]): Boolean
    begin
        exit(CheckRespCenter(DocType, AccRespCenter, UserId));
    end;

    procedure CheckRespCenter(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]; UserCode: Code[50]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        OnBeforeCheckRespCenter2(DocType, AccRespCenter, UserCode, IsHandled, Result);
        if IsHandled then
            exit(Result);

        case DocType of
            DocType::Sales:
                UserRespCenter := GetSalesFilter(UserCode);
            DocType::Purchase:
                UserRespCenter := GetPurchasesFilter(UserCode);
            DocType::Service:
                UserRespCenter := GetServiceFilter(UserCode);
        end;
        if (UserRespCenter <> '') and
           (AccRespCenter <> UserRespCenter)
        then
            exit(false);

        exit(true);
    end;

    procedure GetLocation(DocType: Option Sales,Purchase,Service; AccLocation: Code[10]; RespCenterCode: Code[10]) LocationCode: Code[10]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(DocType, AccLocation, RespCenterCode, LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        case DocType of
            DocType::Sales:
                UserRespCenter := GetSalesFilter();
            DocType::Purchase:
                UserRespCenter := GetPurchasesFilter();
            DocType::Service:
                UserRespCenter := GetServiceFilter();
        end;
        if UserRespCenter <> '' then
            RespCenterCode := UserRespCenter;
        if RespCenter.Get(RespCenterCode) then
            if RespCenter."Location Code" <> '' then
                UserLocation := RespCenter."Location Code";
        if AccLocation <> '' then
            exit(AccLocation);

        exit(UserLocation);
    end;

    procedure CheckAllowedPostingDate(PostingDate: Date)
    begin
        if not IsPostingDateValid(PostingDate) then
            Error(ErrorInfo.Create(PostingDateRangeErr, true));
    end;

    procedure TestAllowedPostingDate(PostingDate: Date; var ErrorText: Text[250]): Boolean
    begin
        if IsPostingDateValid(PostingDate) then
            exit(true);

        ErrorText := CopyStr(PostingDateRangeErr, 1, MaxStrLen(ErrorText));
        exit(false);
    end;

    procedure CheckAllowedVATDatesRange(AllowVATDateFrom: Date; AllowVATDateTo: Date; NotificationType: Option Error,Notification; InvokedBy: Integer)
    begin
        CheckAllowedVATDatesRange(
            AllowVATDateFrom, AllowVATDateTo, NotificationType, InvokedBy,
            UserSetup.FieldCaption("Allow VAT Date From"), UserSetup.FieldCaption("Allow VAT Date To"));
    end;

    procedure CheckAllowedPostingDatesRange(AllowPostingFrom: Date; AllowPostingTo: Date; NotificationType: Option Error,Notification; InvokedBy: Integer)
    begin
        CheckAllowedPostingDatesRange(
            AllowPostingFrom, AllowPostingTo, NotificationType, InvokedBy,
            UserSetup.FieldCaption("Allow Posting From"), UserSetup.FieldCaption("Allow Posting To"));
    end;

    procedure CheckAllowedPostingDatesRange(AllowPostingFrom: Date; AllowPostingTo: Date; NotificationType: Option Error,Notification; InvokedBy: Integer; AllowPostingFromCaption: Text; AllowPostingToCaption: Text)
    var
        Notification: Notification;
    begin
        if AllowPostingFrom <= AllowPostingTo then
            exit;

        if (AllowPostingFrom = 0D) or (AllowPostingTo = 0D) then
            exit;

        if NotificationType = NotificationType::Error then
            Error(AllowedDateErr, AllowPostingFromCaption, AllowPostingToCaption);

        CreateAndSendNotification(InvokedBy, StrSubstNo(AllowedPostingDateMsg, AllowPostingFromCaption, AllowPostingToCaption), Notification);
        Error('');
    end;

    procedure CheckAllowedVATDatesRange(AllowPostingFrom: Date; AllowPostingTo: Date; NotificationType: Option Error,Notification; InvokedBy: Integer; AllowVATFromCaption: Text; AllowVATToCaption: Text)
    var
        Notification: Notification;
    begin
        if AllowPostingFrom <= AllowPostingTo then
            exit;

        if (AllowPostingFrom = 0D) or (AllowPostingTo = 0D) then
            exit;

        if NotificationType = NotificationType::Error then
            Error(AllowedDateErr, AllowVATFromCaption, AllowVATToCaption);

        CreateAndSendNotification(InvokedBy, StrSubstNo(AllowedVATDateMsg, AllowVATFromCaption, AllowVATToCaption), Notification);
        Error('');
    end;

    procedure IsVATDateInAllowedPeriod(VATDate: Date; var SetupRecordID: RecordID; var FieldNo: Integer) Result: Boolean
    var
        VATSetup: Record "VAT Setup";
        UserSetup2: Record "User Setup";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        IsHandled: Boolean;
    begin
        OnBeforeIsVATDateValidWithSetup(VATDate, Result, IsHandled, SetupRecordID, FieldNo);
        if IsHandled then
            exit(Result);

        if not VATReportingDateMgt.IsVATDateEnabled() then
            exit(true);

        if UserId() <> '' then
            if UserSetup2.Get(UserId) then begin
                UserSetup2.CheckAllowedVATDates(1);
                AllowPostingFrom := UserSetup2."Allow VAT Date From";
                AllowPostingTo := UserSetup2."Allow VAT Date To";
                SetupRecordID := UserSetup2.RecordId;
                FieldNo := UserSetup2.FieldNo("Allow VAT Date From");
            end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            VATSetup.Get();
            VATSetup.CheckAllowedVATDates(1);
            AllowPostingFrom := VATSetup."Allow VAT Date From";
            AllowPostingTo := VATSetup."Allow VAT Date To";
            SetupRecordID := VATSetup.RecordId;
            FieldNo := VATSetup.FieldNo("Allow VAT Date From");
        end;
        if AllowPostingTo = 0D then
            AllowPostingTo := DMY2Date(31, 12, 9999);
        exit(VATDate in [AllowPostingFrom .. AllowPostingTo]);
    end;

    local procedure CreateAndSendNotification(InvokedBy: Integer; Message: Text; var Notification: Notification)
    begin
        Notification.Message := Message;
        case InvokedBy of
            Database::"General Ledger Setup":
                Notification.AddAction(OpenGLSetupActionTxt, Codeunit::"Document Notifications", 'ShowGLSetup');
            Database::"User Setup":
                Notification.AddAction(OpenUserSetupActionTxt, Codeunit::"Document Notifications", 'ShowUserSetup');
        end;
        Notification.Send();
    end;

    procedure IsPostingDateValid(PostingDate: Date): Boolean
    var
        RecID: RecordID;
    begin
        exit(IsPostingDateValidWithSetup(PostingDate, RecID));
    end;

    procedure IsPostingDateValidWithSetup(PostingDate: Date; var SetupRecordID: RecordID) Result: Boolean
    var
        UserSetup: Record "User Setup";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        IsHandled: Boolean;
    begin
        OnBeforeIsPostingDateValidWithSetup(PostingDate, Result, IsHandled, SetupRecordID);
        if IsHandled then
            exit(Result);

        if UserId <> '' then
            if UserSetup.Get(UserId) then begin
                UserSetup.CheckAllowedPostingDates(1);
                AllowPostingFrom := UserSetup."Allow Posting From";
                AllowPostingTo := UserSetup."Allow Posting To";
                SetupRecordID := UserSetup.RecordId;
            end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            GLSetup.GetRecordOnce();
            GLSetup.CheckAllowedPostingDates(1);
            AllowPostingFrom := GLSetup."Allow Posting From";
            AllowPostingTo := GLSetup."Allow Posting To";
            SetupRecordID := GLSetup.RecordId;
        end;
        if AllowPostingTo = 0D then
            AllowPostingTo := DMY2Date(31, 12, 9999);
        exit(PostingDate in [AllowPostingFrom .. AllowPostingTo]);
    end;

    procedure IsDeferralPostingDateValidWithSetup(PostingDate: Date; var SetupRecordID: RecordID) Result: Boolean
    var
        LocalUserSetup: Record "User Setup";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        IsHandled: Boolean;
    begin
        OnBeforeIsDeferralPostingDateValidWithSetup(PostingDate, Result, IsHandled, SetupRecordID);
        if IsHandled then
            exit(Result);

        if UserId <> '' then
            if LocalUserSetup.Get(UserId) then begin
                LocalUserSetup.CheckAllowedPostingDates(1);
                AllowPostingFrom := LocalUserSetup."Allow Deferral Posting From";
                AllowPostingTo := LocalUserSetup."Allow Deferral Posting To";
                SetupRecordID := LocalUserSetup.RecordId;
            end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            GLSetup.GetRecordOnce();
            GLSetup.CheckAllowedPostingDates(1);
            AllowPostingFrom := GLSetup."Allow Deferral Posting From";
            AllowPostingTo := GLSetup."Allow Deferral Posting To";
            SetupRecordID := GLSetup.RecordId;
        end;
        if AllowPostingTo = 0D then
            AllowPostingTo := DMY2Date(31, 12, 9999);
        exit(PostingDate in [AllowPostingFrom .. AllowPostingTo]);
    end;

    procedure IsPostingDateValidWithGenJnlTemplate(PostingDate: Date; TemplateName: Code[20]): Boolean
    var
        SetupRecordID: RecordID;
    begin
        exit(IsPostingDateValidWithGenJnlTemplateWithSetup(PostingDate, TemplateName, SetupRecordID));
    end;

    procedure IsPostingDateValidWithGenJnlTemplateWithSetup(PostingDate: Date; TemplateName: Code[20]; var SetupRecordID: RecordID): Boolean
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
    begin
        if TemplateName <> '' then begin
            GLSetup.GetRecordOnce();
            if GLSetup."Journal Templ. Name Mandatory" then begin
                GenJnlTemplate.Get(TemplateName);
                AllowPostingFrom := GenJnlTemplate."Allow Posting Date From";
                AllowPostingTo := GenJnlTemplate."Allow Posting Date To";
                SetupRecordID := GenJnlTemplate.RecordId();
            end;
        end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then
            exit(IsPostingDateValidWithSetup(PostingDate, SetupRecordID));

        if (AllowPostingFrom <= PostingDate) and (AllowPostingTo = 0D) then
            exit(true);

        if (PostingDate < AllowPostingFrom) or (PostingDate > AllowPostingTo) then
            exit(false);

        exit(true);
    end;

    procedure GetSalesInvoicePostingPolicy(var PostQty: Boolean; var PostAmount: Boolean)
    var
        UserSetupForPostingPolicy: Record "User Setup";
    begin
        PostQty := false;
        PostAmount := false;

        if UserId() <> '' then begin
            UserSetupForPostingPolicy.SetLoadFields("Sales Invoice Posting Policy");
            if UserSetupForPostingPolicy.Get(UserId()) then
                case UserSetupForPostingPolicy."Sales Invoice Posting Policy" of
                    Enum::"Invoice Posting Policy"::Prohibited:
                        begin
                            PostQty := true;
                            PostAmount := false;
                        end;
                    Enum::"Invoice Posting Policy"::Mandatory:
                        begin
                            PostQty := true;
                            PostAmount := true;
                        end;
                end;
        end;

        OnAfterGetSalesInvoicePostingPolicy(UserSetupForPostingPolicy, PostQty, PostAmount);
    end;

    procedure GetPurchaseInvoicePostingPolicy(var PostQty: Boolean; var PostAmount: Boolean)
    var
        UserSetupForPostingPolicy: Record "User Setup";
    begin
        PostQty := false;
        PostAmount := false;

        if UserId() <> '' then begin
            UserSetupForPostingPolicy.SetLoadFields("Purch. Invoice Posting Policy");
            if UserSetupForPostingPolicy.Get(UserId()) then
                case UserSetupForPostingPolicy."Purch. Invoice Posting Policy" of
                    Enum::"Invoice Posting Policy"::Prohibited:
                        begin
                            PostQty := true;
                            PostAmount := false;
                        end;
                    Enum::"Invoice Posting Policy"::Mandatory:
                        begin
                            PostQty := true;
                            PostAmount := true;
                        end;
                end;
        end;

        OnAfterGetPurchaseInvoicePostingPolicy(UserSetupForPostingPolicy, PostQty, PostAmount);
    end;

    procedure GetServiceInvoicePostingPolicy(var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean)
    var
        UserSetupForPostingPolicy: Record "User Setup";
    begin
        Ship := false;
        Consume := false;
        Invoice := false;

        if UserId() <> '' then begin
            UserSetupForPostingPolicy.SetLoadFields("Service Invoice Posting Policy");
            if UserSetupForPostingPolicy.Get(UserId()) then
                case UserSetupForPostingPolicy."Service Invoice Posting Policy" of
                    Enum::"Invoice Posting Policy"::Prohibited:
                        begin
                            Ship := true;
                            Consume := true;
                            Invoice := false;
                        end;
                    Enum::"Invoice Posting Policy"::Mandatory:
                        begin
                            Ship := true;
                            Consume := false;
                            Invoice := true;
                        end;
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchFilter(var UserSetup: Record "User Setup"; var UserRespCenter: Code[10]; var UserLocation: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesFilter(var UserSetup: Record "User Setup"; var UserRespCenter: Code[10]; var UserLocation: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceFilter(var UserSetup: Record "User Setup"; var UserRespCenter: Code[10]; var UserLocation: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesFilterProcedure(UserCode: Code[50]; Result: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchasesFilter(UserCode: Code[50]; Result: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceFilterProcedure(UserCode: Code[50]; Result: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRespCenter2(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]; UserCode: Code[50]; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(DocType: Option Sales,Purchase,Service; AccLocation: Code[10]; RespCenterCode: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRespCenter(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]; var IsHandled: Boolean; var UserRespCenter: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesFilter(UserCode: Code[50]; var UserLocation: Code[10]; var UserRespCenter: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsPostingDateValidWithSetup(PostingDate: Date; var Result: Boolean; var IsHandled: Boolean; var SetupRecordID: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDeferralPostingDateValidWithSetup(PostingDate: Date; var Result: Boolean; var IsHandled: Boolean; var SetupRecordID: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVATDateValidWithSetup(VATDate: Date; var Result: Boolean; var IsHandled: Boolean; var SetupRecordID: RecordID; var FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesInvoicePostingPolicy(var UserSetup: Record "User Setup"; var PostQty: Boolean; var PostAmount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchaseInvoicePostingPolicy(var UserSetup: Record "User Setup"; var PostQty: Boolean; var PostAmount: Boolean)
    begin
    end;
}

