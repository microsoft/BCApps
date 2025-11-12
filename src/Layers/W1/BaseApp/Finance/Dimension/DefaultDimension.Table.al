// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Bank.BankAccount;
using Microsoft.CashFlow.Setup;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;
using System.Text;
using System.Globalization;

table 352 "Default Dimension"
{
    Caption = 'Default Dimension';
    LookupPageID = "Default Dimensions";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnLookup()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
            begin
                Clear(TempAllObjWithCaption);
                DimensionManagement.DefaultDimObjectNoList(TempAllObjWithCaption);
                if PAGE.RunModal(PAGE::Objects, TempAllObjWithCaption) = ACTION::LookupOK then begin
                    "Table ID" := TempAllObjWithCaption."Object ID";
                    Validate("Table ID");
                end;
            end;

            trigger OnValidate()
            var
                TempAllObjWithCaption: Record AllObjWithCaption temporary;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTableID(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CalcFields("Table Caption");
                DimensionManagement.DefaultDimObjectNoList(TempAllObjWithCaption);
                TempAllObjWithCaption.SetRange("Object Type", TempAllObjWithCaption."Object Type"::Table);
                TempAllObjWithCaption.SetRange("Object ID", "Table ID");
                if TempAllObjWithCaption.IsEmpty() then
                    FieldError("Table ID");
            end;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                RecRef: RecordRef;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "No." = '' then
                    exit;
                RecRef.Open("Table ID");
                SetRangeToLastFieldInPrimaryKey(RecRef, "No.");
                if RecRef.IsEmpty() then
                    Error(NoValidateErr, "No.", RecRef.Caption);
                RecRef.Close();
            end;
        }
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                CheckDimension("Dimension Code");
                UpdateDimensionId();
                if "Dimension Code" <> xRec."Dimension Code" then
                    Validate("Dimension Value Code", '');
            end;
        }
        field(4; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"),
                                                         Blocked = const(false));

            trigger OnValidate()
            begin
                CheckDimensionValue("Dimension Code", "Dimension Value Code");
                UpdateDimensionValueId();
            end;
        }
        field(5; "Value Posting"; Enum "Default Dimension Value Posting Type")
        {
            Caption = 'Value Posting';

            trigger OnValidate()
            var
                DimValuePerAccount: Record "Dim. Value per Account";
            begin
                if "Value Posting" = "Value Posting"::"No Code" then
                    TestField("Dimension Value Code", '');
                if not IsTemporary() then
                    ClearAllowedValuesFilter(DimValuePerAccount);
            end;
        }
        field(6; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Multi Selection Action"; Option)
        {
            Caption = 'Multi Selection Action';
            OptionCaption = ' ,Change,Delete';
            OptionMembers = " ",Change,Delete;
        }
        field(8; "Parent Type"; Enum "Default Dimension Parent Type")
        {
            Caption = 'Parent Type';

            trigger OnValidate()
            begin
                case "Parent Type" of
                    "Parent Type"::Customer:
                        "Table ID" := Database::Customer;
                    "Parent Type"::Employee:
                        "Table ID" := Database::Employee;
                    "Parent Type"::Item:
                        "Table ID" := Database::Item;
                    "Parent Type"::Vendor:
                        "Table ID" := Database::Vendor;
                end;
            end;
        }
        field(10; "Allowed Values Filter"; Text[250])
        {
            Caption = 'Allowed Values Filter';

            trigger OnValidate()
            var
                DimValuePerAccount: Record "Dim. Value per Account";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAllowedValuesFilter(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Dimension Code");
                TestField("Value Posting", Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
                if not IsTemporary() then
                    UpdateDimValuesPerAccountFromAllowedValuesFilter(DimValuePerAccount);
            end;
        }
        field(20; "Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup("Dimension Value".Name where("Dimension Code" = field("Dimension Code"), Code = field("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8000; ParentId; Guid)
        {
            Caption = 'ParentId';
            DataClassification = SystemMetadata;
            TableRelation = if ("Table ID" = const(15)) "G/L Account".SystemId
            else
            if ("Table ID" = const(18)) Customer.SystemId
            else
            if ("Table ID" = const(23)) Vendor.SystemId
            else
            if ("Table ID" = const(5200)) Employee.SystemId;

            trigger OnValidate()
            begin
                if "Parent Type" <> "Parent Type"::" " then
                    UpdateNo(ParentId, "Parent Type")
                else
                    UpdateTableIdAndNo(ParentId);
            end;
        }
        field(8001; DimensionId; Guid)
        {
            Caption = 'DimensionId';
            DataClassification = SystemMetadata;
            TableRelation = Dimension.SystemId;

            trigger OnValidate()
            var
                Dimension: Record Dimension;
            begin
                if not Dimension.GetBySystemId(DimensionId) then
                    Error(DimensionIdDoesNotMatchADimensionErr);

                CheckDimension(Dimension.Code);
                "Dimension Code" := Dimension.Code;
            end;
        }
        field(8002; DimensionValueId; Guid)
        {
            Caption = 'DimensionValueId';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".SystemId;

            trigger OnValidate()
            var
                DimensionValue: Record "Dimension Value";
            begin
                if IsNullGuid(DimensionValueId) then begin
                    "Dimension Value Code" := '';
                    exit;
                end;

                if not DimensionValue.GetBySystemId(DimensionValueId) then
                    Error(DimensionValueIdDoesNotMatchADimensionValueErr);

                if "Dimension Code" = '' then
                    "Dimension Code" := DimensionValue."Dimension Code"
                else
                    if "Dimension Code" <> DimensionValue."Dimension Code" then
                        Error(DimensionIdMismatchErr);
                CheckDimensionValue("Dimension Code", DimensionValue.Code);
                "Dimension Value Code" := DimensionValue.Code;
            end;
        }
    }

    keys
    {
        key(Key1; "Table ID", "No.", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Code")
        {
        }
        key(Key3; "Parent Type", ParentID)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, DimensionManagement, IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.Get();
        if "Dimension Code" = GeneralLedgerSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", '');
        if "Dimension Code" = GeneralLedgerSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", '');
        DimensionManagement.DefaultDimOnDelete(Rec);

        DimValuePerAccount.SetRange("Table ID", "Table ID");
        DimValuePerAccount.SetRange("No.", "No.");
        DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
        DimValuePerAccount.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, DimensionManagement, IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.Get();
        if "Dimension Code" = GeneralLedgerSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", "Dimension Value Code");
        if "Dimension Code" = GeneralLedgerSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", "Dimension Value Code");
        DimensionManagement.DefaultDimOnInsert(Rec);
        UpdateParentId();
        UpdateParentType();
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Rec, DimensionManagement, IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.Get();
        if "Dimension Code" = GeneralLedgerSetup."Global Dimension 1 Code" then
            UpdateGlobalDimCode(1, "Table ID", "No.", "Dimension Value Code");
        if "Dimension Code" = GeneralLedgerSetup."Global Dimension 2 Code" then
            UpdateGlobalDimCode(2, "Table ID", "No.", "Dimension Value Code");
        DimensionManagement.DefaultDimOnModify(Rec);
    end;

    trigger OnRename()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRename(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Table ID" <> xRec."Table ID") or ("Dimension Code" <> xRec."Dimension Code") then
            Error(CannotRenameErr, TableCaption);

        DimValuePerAccount.RenameNo("Table ID", xRec."No.", "No.", "Dimension Code");
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionManagement: Codeunit DimensionManagement;

        CannotRenameErr: Label 'You can''t rename a %1.', Comment = '%1 - table caption';
        DimensionIdDoesNotMatchADimensionErr: Label 'The "dimensionId" does not match to a Dimension.', Locked = true;
        DimensionValueIdDoesNotMatchADimensionValueErr: Label 'The "dimensionValueId" does not match to a Dimension Value.', Locked = true;
        DimensionIdMismatchErr: Label 'The "dimensionId" and "dimensionValueId" match to different Dimension records.', Locked = true;
        ParentIdDoesNotMatchAnIntegrationRecordErr: Label 'The "parenteId" does not match to any entity.', Locked = true;
        RequestedRecordIsNotSupportedErr: Label 'Images are not supported for requested entity - %1.', Locked = true;
        NoValidateErr: Label 'The field No. of table Default Dimension contains a value (%1) that cannot be found in the related table (%2).', Comment = '%1 - a master table record key value; %2 - table caption. ';
        MultipleParentsFoundErr: Label 'Multiple parents have been found for the specified criteria.';
        ParentNotFoundErr: Label 'Parent is not found.';
        InvalidAllowedValuesFilterErr: Label 'There are no dimension values for allowed values filter %1.', Comment = '%1 - allowed values filter';
        DefaultDimValueErr: Label 'You cannot block dimension value %1 because it is a default value for %2, %3.', Comment = '%1 = dimension value code and %2- table name, %3 - account number';

    procedure GetCaption() Result: Text[250]
    var
        ObjectTranslation: Record "Object Translation";
        CurrTableID: Integer;
        NewTableID: Integer;
        NewNo: Code[20];
        SourceTableName: Text[250];
        IsHandled: Boolean;
    begin
        if not Evaluate(NewTableID, GetFilter("Table ID")) then
            exit('');

        CurrTableID := 0;
        if NewTableID = 0 then
            if GetRangeMin("Table ID") = GetRangeMax("Table ID") then
                NewTableID := GetRangeMin("Table ID")
            else
                NewTableID := 0;

        if NewTableID <> CurrTableID then
            SourceTableName := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, NewTableID);
        CurrTableID := NewTableID;

        if GetFilter("No.") <> '' then
            if GetRangeMin("No.") = GetRangeMax("No.") then
                NewNo := GetRangeMin("No.")
            else
                NewNo := '';

        IsHandled := false;
        OnGetCaptionOnAfterAssignNewNo(NewTableID, SourceTableName, NewNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if NewTableID <> 0 then
            exit(StrSubstNo('%1 %2', SourceTableName, NewNo));

        exit('');
    end;

    procedure UpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateGlobalDimCode(GlobalDimCodeNo, TableID, AccNo, NewDimValue, IsHandled);
        if IsHandled then
            exit;

        case TableID of
            Database::"G/L Account":
                UpdateGLAccGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::Customer:
                UpdateCustGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::Vendor:
                UpdateVendGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::Item:
                UpdateItemGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Resource Group":
                UpdateResGrGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::Resource:
                UpdateResGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::Job:
                UpdateJobGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Bank Account":
                UpdateBankGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::Employee:
                UpdateEmpoyeeGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Fixed Asset":
                UpdateFAGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::Insurance:
                UpdateInsuranceGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Responsibility Center":
                UpdateRespCenterGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Salesperson/Purchaser":
                UpdateSalesPurchGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::Campaign:
                UpdateCampaignGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Cash Flow Manual Expense":
                UpdateNeutrPayGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Cash Flow Manual Revenue":
                UpdateNeutrRevGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Vendor Templ.":
                UpdateVendorTemplGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Customer Templ.":
                UpdateCustomerTemplGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Item Templ.":
                UpdateItemTemplGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            Database::"Employee Templ.":
                UpdateEmployeeTemplGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
            else
                OnAfterUpdateGlobalDimCode(GlobalDimCodeNo, TableID, AccNo, NewDimValue);
        end;
    end;

    local procedure UpdateGLAccGlobalDimCode(GlobalDimCodeNo: Integer; GLAccNo: Code[20]; NewDimValue: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(GLAccNo) then begin
            case GlobalDimCodeNo of
                1:
                    GLAccount."Global Dimension 1 Code" := NewDimValue;
                2:
                    GLAccount."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateGLAccGlobalDimCodeOnCaseElse(GlobalDimCodeNo, GLAccNo, NewDimValue);
            end;
            OnUpdateGLAccGlobalDimCodeOnBeforeGLAccModify(GLAccount, NewDimValue, GlobalDimCodeNo);
            GLAccount.Modify(true);
        end;
    end;

    local procedure UpdateCustGlobalDimCode(GlobalDimCodeNo: Integer; CustNo: Code[20]; NewDimValue: Code[20])
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustNo) then begin
            case GlobalDimCodeNo of
                1:
                    Customer."Global Dimension 1 Code" := NewDimValue;
                2:
                    Customer."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateCustGlobalDimCodeOnCaseElse(GlobalDimCodeNo, CustNo, NewDimValue);
            end;
            OnUpdateCustGlobalDimCodeOnBeforeCustModify(Customer, NewDimValue, GlobalDimCodeNo);
            Customer.Modify(true);
        end;
    end;

    local procedure UpdateVendGlobalDimCode(GlobalDimCodeNo: Integer; VendNo: Code[20]; NewDimValue: Code[20])
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendNo) then begin
            case GlobalDimCodeNo of
                1:
                    Vendor."Global Dimension 1 Code" := NewDimValue;
                2:
                    Vendor."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateVendGlobalDimCodeOnCaseElse(GlobalDimCodeNo, VendNo, NewDimValue);
            end;
            OnUpdateVendGlobalDimCodeOnBeforeVendModify(Vendor, NewDimValue, GlobalDimCodeNo);
            Vendor.Modify(true);
        end;
    end;

    local procedure UpdateItemGlobalDimCode(GlobalDimCodeNo: Integer; ItemNo: Code[20]; NewDimValue: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then begin
            case GlobalDimCodeNo of
                1:
                    Item."Global Dimension 1 Code" := NewDimValue;
                2:
                    Item."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateItemGlobalDimCodeOnCaseElse(GlobalDimCodeNo, ItemNo, NewDimValue);
            end;
            OnUpdateItemGlobalDimCodeOnBeforeItemModify(Item, NewDimValue, GlobalDimCodeNo);
            Item.Modify(true);
        end;
    end;

    local procedure UpdateResGrGlobalDimCode(GlobalDimCodeNo: Integer; ResGrNo: Code[20]; NewDimValue: Code[20])
    var
        ResourceGroup: Record "Resource Group";
    begin
        if ResourceGroup.Get(ResGrNo) then begin
            case GlobalDimCodeNo of
                1:
                    ResourceGroup."Global Dimension 1 Code" := NewDimValue;
                2:
                    ResourceGroup."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateResGrGlobalDimCodeOnCaseElse(GlobalDimCodeNo, ResGrNo, NewDimValue);
            end;
            OnUpdateResGrGlobalDimCodeOnBeforeResGrModify(ResourceGroup, NewDimValue, GlobalDimCodeNo);
            ResourceGroup.Modify(true);
        end;
    end;

    local procedure UpdateResGlobalDimCode(GlobalDimCodeNo: Integer; ResNo: Code[20]; NewDimValue: Code[20])
    var
        Resource: Record Resource;
    begin
        if Resource.Get(ResNo) then begin
            case GlobalDimCodeNo of
                1:
                    Resource."Global Dimension 1 Code" := NewDimValue;
                2:
                    Resource."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateResGlobalDimCodeCaseElse(GlobalDimCodeNo, ResNo, NewDimValue);
            end;
            OnUpdateResGlobalDimCodeOnBeforeResModify(Resource, NewDimValue, GlobalDimCodeNo);
            Resource.Modify(true);
        end;
    end;

    local procedure UpdateJobGlobalDimCode(GlobalDimCodeNo: Integer; JobNo: Code[20]; NewDimValue: Code[20])
    var
        Job: Record Job;
    begin
        if Job.Get(JobNo) then begin
            case GlobalDimCodeNo of
                1:
                    Job."Global Dimension 1 Code" := NewDimValue;
                2:
                    Job."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateJobGlobalDimCodeCaseElse(GlobalDimCodeNo, JobNo, NewDimValue);
            end;
            OnUpdateJobGlobalDimCodeOnBeforeJobModify(Job, NewDimValue, GlobalDimCodeNo);
            Job.Modify(true);
        end;
    end;

    local procedure UpdateBankGlobalDimCode(GlobalDimCodeNo: Integer; BankAccNo: Code[20]; NewDimValue: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.Get(BankAccNo) then begin
            case GlobalDimCodeNo of
                1:
                    BankAccount."Global Dimension 1 Code" := NewDimValue;
                2:
                    BankAccount."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateBankGlobalDimCodeCaseElse(GlobalDimCodeNo, BankAccNo, NewDimValue);
            end;
            OnUpdateBankGlobalDimCodeOnBeforeBankModify(BankAccount, NewDimValue, GlobalDimCodeNo);
            BankAccount.Modify(true);
        end;
    end;

    local procedure UpdateEmpoyeeGlobalDimCode(GlobalDimCodeNo: Integer; EmployeeNo: Code[20]; NewDimValue: Code[20])
    var
        Employee: Record Employee;
    begin
        if Employee.Get(EmployeeNo) then begin
            case GlobalDimCodeNo of
                1:
                    Employee."Global Dimension 1 Code" := NewDimValue;
                2:
                    Employee."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateEmpoyeeGlobalDimCodeCaseElse(GlobalDimCodeNo, EmployeeNo, NewDimValue);
            end;
            OnUpdateEmployeeGlobalDimCodeOnBeforeEmployeeModify(Employee, NewDimValue, GlobalDimCodeNo);
            Employee.Modify(true);
        end;
    end;

    local procedure UpdateFAGlobalDimCode(GlobalDimCodeNo: Integer; FANo: Code[20]; NewDimValue: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if FixedAsset.Get(FANo) then begin
            case GlobalDimCodeNo of
                1:
                    FixedAsset."Global Dimension 1 Code" := NewDimValue;
                2:
                    FixedAsset."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateFAGlobalDimCodeCaseElse(GlobalDimCodeNo, FANo, NewDimValue);
            end;
            OnUpdateFAGlobalDimCodeOnBeforeFAModify(FixedAsset, NewDimValue, GlobalDimCodeNo);
            FixedAsset.Modify(true);
        end;
    end;

    local procedure UpdateInsuranceGlobalDimCode(GlobalDimCodeNo: Integer; InsuranceNo: Code[20]; NewDimValue: Code[20])
    var
        Insurance: Record Insurance;
    begin
        if Insurance.Get(InsuranceNo) then begin
            case GlobalDimCodeNo of
                1:
                    Insurance."Global Dimension 1 Code" := NewDimValue;
                2:
                    Insurance."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateInsuranceGlobalDimCodeCaseElse(GlobalDimCodeNo, InsuranceNo, NewDimValue);
            end;
            OnUpdateInsuranceGlobalDimCodeOnBeforeInsuranceModify(Insurance, NewDimValue, GlobalDimCodeNo);
            Insurance.Modify(true);
        end;
    end;

    local procedure UpdateRespCenterGlobalDimCode(GlobalDimCodeNo: Integer; RespCenterNo: Code[20]; NewDimValue: Code[20])
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        if ResponsibilityCenter.Get(RespCenterNo) then begin
            case GlobalDimCodeNo of
                1:
                    ResponsibilityCenter."Global Dimension 1 Code" := NewDimValue;
                2:
                    ResponsibilityCenter."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateRespCenterGlobalDimCodeCaseElse(GlobalDimCodeNo, RespCenterNo, NewDimValue);
            end;
            OnUpdateRespCenterGlobalDimCodeOnBeforeRespCenterModify(ResponsibilityCenter, NewDimValue, GlobalDimCodeNo);
            ResponsibilityCenter.Modify(true);
        end;
    end;

    local procedure UpdateSalesPurchGlobalDimCode(GlobalDimCodeNo: Integer; SalespersonPurchaserNo: Code[20]; NewDimValue: Code[20])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if SalespersonPurchaser.Get(SalespersonPurchaserNo) then begin
            case GlobalDimCodeNo of
                1:
                    SalespersonPurchaser."Global Dimension 1 Code" := NewDimValue;
                2:
                    SalespersonPurchaser."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateSalesPurchGlobalDimCodeCaseElse(GlobalDimCodeNo, SalespersonPurchaserNo, NewDimValue);
            end;
            SalespersonPurchaser.Modify(true);
        end;
    end;

    local procedure UpdateCampaignGlobalDimCode(GlobalDimCodeNo: Integer; CampaignNo: Code[20]; NewDimValue: Code[20])
    var
        Campaign: Record Campaign;
    begin
        if Campaign.Get(CampaignNo) then begin
            case GlobalDimCodeNo of
                1:
                    Campaign."Global Dimension 1 Code" := NewDimValue;
                2:
                    Campaign."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateCampaignGlobalDimCodeCaseElse(GlobalDimCodeNo, CampaignNo, NewDimValue);
            end;
            Campaign.Modify(true);
        end;
    end;

    local procedure UpdateNeutrPayGlobalDimCode(GlobalDimCodeNo: Integer; CFManualExpenseNo: Code[20]; NewDimValue: Code[20])
    var
        CashFlowManualExpense: Record "Cash Flow Manual Expense";
    begin
        if CashFlowManualExpense.Get(CFManualExpenseNo) then begin
            case GlobalDimCodeNo of
                1:
                    CashFlowManualExpense."Global Dimension 1 Code" := NewDimValue;
                2:
                    CashFlowManualExpense."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateNeutrPayGlobalDimCodeCaseElse(GlobalDimCodeNo, CFManualExpenseNo, NewDimValue);
            end;
            CashFlowManualExpense.Modify(true);
        end;
    end;

    local procedure UpdateNeutrRevGlobalDimCode(GlobalDimCodeNo: Integer; CFManualRevenueNo: Code[20]; NewDimValue: Code[20])
    var
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
    begin
        if CashFlowManualRevenue.Get(CFManualRevenueNo) then begin
            case GlobalDimCodeNo of
                1:
                    CashFlowManualRevenue."Global Dimension 1 Code" := NewDimValue;
                2:
                    CashFlowManualRevenue."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateNeutrRevGlobalDimCodeCaseElse(GlobalDimCodeNo, CFManualRevenueNo, NewDimValue);
            end;
            CashFlowManualRevenue.Modify(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    local procedure CheckDimension(DimensionCode: Code[20])
    begin
        if not DimensionManagement.CheckDim(DimensionCode) then
            Error(DimensionManagement.GetDimErr());
    end;

    local procedure CheckDimensionValue(DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        if not DimensionManagement.CheckDimValue(DimensionCode, DimensionValueCode) then
            Error(DimensionManagement.GetDimErr());
        if "Value Posting" = "Value Posting"::"No Code" then
            TestField("Dimension Value Code", '');
        CheckDimensionValueAllowedForAccount();
    end;

    local procedure CheckDimensionValueAllowedForAccount()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        if DimValuePerAccount.Get("Table ID", "No.", "Dimension Code", "Dimension Value Code") then
            if not DimValuePerAccount.Allowed then
                Error(DimensionManagement.GetNotAllowedDimValuePerAccount(Rec, "Dimension Value Code"));
    end;

    procedure ClearAllowedValuesFilter(var DimValuePerAccount: Record "Dim. Value per Account")
    begin
        if (xRec."Value Posting" = "Value Posting"::"Code Mandatory") and ("Value Posting" <> "Value Posting"::"Code Mandatory") then begin
            DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
            DimValuePerAccount.SetRange("Table ID", "Table ID");
            DimValuePerAccount.SetRange("No.", "No.");
            if not DimValuePerAccount.IsEmpty() then begin
                DimValuePerAccount.DeleteAll();
                "Allowed Values Filter" := '';
            end;
        end;
    end;

    procedure CreateDimValuePerAccountFromDimValue(DimValue: Record "Dimension Value"; ShouldUpdateAllowed: Boolean)
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.Init();
        DimValuePerAccount."Dimension Code" := DimValue."Dimension Code";
        DimValuePerAccount."Dimension Value Code" := DimValue.Code;
        DimValuePerAccount."Table ID" := "Table ID";
        DimValuePerAccount."No." := "No.";
        if not ShouldUpdateAllowed then
            DimValuePerAccount.Allowed := false
        else
            DimValuePerAccount.Allowed := IncludedInAllowedValuesFilter(DimValuePerAccount);
        DimValuePerAccount.Insert();
    end;

    procedure IncludedInAllowedValuesFilter(DimValuePerAccount: Record "Dim. Value per Account"): Boolean
    var
        TempDimValuePerAccount: Record "Dim. Value per Account" temporary;
    begin
        TempDimValuePerAccount := DimValuePerAccount;
        TempDimValuePerAccount.Insert();

        TempDimValuePerAccount.SetRange("Table ID", DimValuePerAccount."Table ID");
        TempDimValuePerAccount.SetRange("No.", DimValuePerAccount."No.");
        TempDimValuePerAccount.SetRange("Dimension Code", DimValuePerAccount."Dimension Code");
        TempDimValuePerAccount.SetFilter("Dimension Value Code", "Allowed Values Filter");

        if not TempDimValuePerAccount.IsEmpty() then
            exit(true);
    end;

    procedure UpdateDimValuesPerAccountFromAllowedValuesFilter(var DimValuePerAccount: Record "Dim. Value per Account")
    begin
        if "Allowed Values Filter" = '' then begin
            DimValuePerAccount.SetRange("Table ID", "Table ID");
            DimValuePerAccount.SetRange("No.", "No.");
            DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
            DimValuePerAccount.DeleteAll();
            exit;
        end;

        DimensionManagement.SyncDimValuePerAccountWithDimValues(Rec);

        CheckDimensionValuesInFilter();

        SetDimValuesPerAccountByAllowedValuesFilter(DimValuePerAccount);

        if ("Dimension Value Code" <> '') and DimValuePerAccount.Get("Table ID", "No.", "Dimension Code", "Dimension Value Code") then
            if not DimValuePerAccount.Allowed then
                CheckDisallowedDimensionValue(DimValuePerAccount);
    end;

    local procedure SetDimValuesPerAccountByAllowedValuesFilter(var DimValuePerAccount: Record "Dim. Value per Account")
    begin
        DimValuePerAccount.Reset();
        DimValuePerAccount.SetRange("Table ID", "Table ID");
        DimValuePerAccount.SetRange("No.", "No.");
        DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
        DimValuePerAccount.ModifyAll(Allowed, false);
        DimValuePerAccount.SetFilter("Dimension Value Code", "Allowed Values Filter");
        DimValuePerAccount.ModifyAll(Allowed, true);
    end;

    local procedure CheckDimensionValuesInFilter()
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", "Dimension Code");
        DimensionValue.SetFilter(Code, "Allowed Values Filter");
        if DimensionValue.IsEmpty() then
            Error(InvalidAllowedValuesFilterErr, "Allowed Values Filter");
    end;

    procedure CheckDisallowedDimensionValue(DimValuePerAccount: Record "Dim. Value per Account")
    begin
        if "Dimension Value Code" = DimValuePerAccount."Dimension Value Code" then
            Error(DefaultDimValueErr, DimValuePerAccount."Dimension Value Code", DimValuePerAccount.GetTableCaption(), "No.");
    end;

    procedure UpdateDefaultDimensionAllowedValuesFilter()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
        AllowedValues: Text[250];
    begin
        AllowedValues := GetAllowedValuesFilter();
        if AllowedValues <> "Allowed Values Filter" then begin
            "Allowed Values Filter" := AllowedValues;
            if "Allowed Values Filter" = '' then begin
                DimValuePerAccount.SetRange("Table ID", "Table ID");
                DimValuePerAccount.SetRange("No.", "No.");
                DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
                DimValuePerAccount.DeleteAll();
            end else
                CheckDimensionValuesInFilter();
            Modify();
        end;
    end;

    procedure GetAllowedValuesFilter(): Text[250]
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        exit(CopyStr(GetFullAllowedValuesFilter(DimValuePerAccount), 1, MaxStrLen("Allowed Values Filter")));
    end;

    procedure GetFullAllowedValuesFilter(var DimValuePerAccount: Record "Dim. Value per Account"): Text
    var
        SelectionFilterMgt: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        DimValuePerAccount.SetRange("Dimension Code", "Dimension Code");
        DimValuePerAccount.SetRange("Table ID", "Table ID");
        DimValuePerAccount.SetRange("No.", "No.");
        DimValuePerAccount.Setrange(Allowed, false);
        if DimValuePerAccount.IsEmpty() then
            exit('');
        DimensionManagement.CheckIfNoAllowedValuesSelected(DimValuePerAccount);
        RecRef.GetTable(DimValuePerAccount);
        exit(SelectionFilterMgt.GetSelectionFilter(RecRef, DimValuePerAccount.FieldNo("Dimension Value Code")));
    end;

    local procedure SetRangeToLastFieldInPrimaryKey(RecRef: RecordRef; Value: Code[20])
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetRangeToLastFieldInPrimaryKey(RecRef, Value, IsHandled);
        if not IsHandled then begin
            KeyRef := RecRef.KeyIndex(1);
            FieldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
            FieldRef.SetRange(Value);
        end;
        OnAfterSetRangeToLastFieldInPrimaryKey(RecRef, Value, FieldRef);
    end;

    local procedure UpdateNo(ParentId: Guid; ParentType: Enum "Default Dimension Parent Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
    begin
        case ParentType of
            "Parent Type"::Customer:
                begin
                    Customer.SetLoadFields("No.");
                    if Customer.GetBySystemId(ParentId) then begin
                        "No." := Customer."No.";
                        exit;
                    end;
                end;
            "Parent Type"::Employee:
                begin
                    Employee.SetLoadFields("No.");
                    if Employee.GetBySystemId(ParentId) then begin
                        "No." := Employee."No.";
                        exit;
                    end;
                end;
            "Parent Type"::Item:
                begin
                    Item.SetLoadFields("No.");
                    if Item.GetBySystemId(ParentId) then begin
                        "No." := Item."No.";
                        exit;
                    end;
                end;
            "Parent Type"::Vendor:
                begin
                    Vendor.SetLoadFields("No.");
                    if Vendor.GetBySystemId(ParentId) then begin
                        "No." := Vendor."No.";
                        exit;
                    end;
                end;
        end;
        Error(ParentNotFoundErr);
    end;

    local procedure UpdateTableIdAndNo(Id: Guid)
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        ParentRecordRef: RecordRef;
        ParentRecordRefId: RecordId;
    begin
        if not GetRecordRefFromFilter(Id, ParentRecordRef) then
            Error(ParentIdDoesNotMatchAnIntegrationRecordErr);

        ParentRecordRefId := ParentRecordRef.RecordId();

        case ParentRecordRefId.TableNo() of
            Database::Item:
                begin
                    Item.SetLoadFields("No.");
                    Item.Get(ParentRecordRefId);
                    "No." := Item."No.";
                    "Parent Type" := "Parent Type"::Item;
                end;
            Database::Customer:
                begin
                    Customer.SetLoadFields("No.");
                    Customer.Get(ParentRecordRefId);
                    "No." := Customer."No.";
                    "Parent Type" := "Parent Type"::Customer;
                end;
            Database::Vendor:
                begin
                    Vendor.SetLoadFields("No.");
                    Vendor.Get(ParentRecordRefId);
                    "No." := Vendor."No.";
                    "Parent Type" := "Parent Type"::Vendor;
                end;
            Database::Employee:
                begin
                    Employee.SetLoadFields("No.");
                    Employee.Get(ParentRecordRefId);
                    "No." := Employee."No.";
                    "Parent Type" := "Parent Type"::Employee;
                end;
            else
                ThrowEntityNotSupportedError(ParentRecordRefId.TableNo());
        end;

        "Table ID" := ParentRecordRefId.TableNo();
    end;

    local procedure GetRecordRefFromFilter(IDFilter: Text; var ParentRecordRef: RecordRef): Boolean
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        RecordFound: Boolean;
    begin
        Item.SetFilter(SystemId, IDFilter);
        if Item.FindFirst() then begin
            ParentRecordRef.GetTable(Item);
            RecordFound := true;
        end;

        Customer.SetFilter(SystemId, IDFilter);
        if Customer.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Customer);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        Vendor.SetFilter(SystemId, IDFilter);
        if Vendor.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Vendor);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        Employee.SetFilter(SystemId, IDFilter);
        if Employee.FindFirst() then
            if not RecordFound then begin
                ParentRecordRef.GetTable(Employee);
                RecordFound := true;
            end else
                Error(MultipleParentsFoundErr);

        exit(RecordFound);
    end;

    procedure UpdateParentType(): Boolean
    var
        NewParentType: Enum "Default Dimension Parent Type";
    begin
        case "Table ID" of
            Database::Item:
                NewParentType := "Parent Type"::Item;
            Database::Customer:
                NewParentType := "Parent Type"::Customer;
            Database::Vendor:
                NewParentType := "Parent Type"::Vendor;
            Database::Employee:
                NewParentType := "Parent Type"::Employee;
            else
                NewParentType := "Parent Type"::" ";
        end;

        if NewParentType = "Parent Type" then
            exit(false);

        "Parent Type" := NewParentType;
        exit(true);
    end;

    procedure UpdateParentId(): Boolean
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        NewParentId: Guid;
    begin
        case "Table ID" of
            Database::Item:
                begin
                    Item.SetLoadFields(SystemId);
                    if Item.Get("No.") then
                        NewParentId := Item.SystemId;
                end;
            Database::Customer:
                begin
                    Customer.SetLoadFields(SystemId);
                    if Customer.Get("No.") then
                        NewParentId := Customer.SystemId;
                end;
            Database::Vendor:
                begin
                    Vendor.SetLoadFields(SystemId);
                    if Vendor.Get("No.") then
                        NewParentId := Vendor.SystemId;
                end;
            Database::Employee:
                begin
                    Employee.SetLoadFields(SystemId);
                    if Employee.Get("No.") then
                        NewParentId := Employee.SystemId;
                end;
        end;

        if NewParentId = ParentId then
            exit(false);

        ParentId := NewParentId;
        exit(true);
    end;

    local procedure UpdateDimensionId(): Boolean
    var
        Dimension: Record Dimension;
    begin
        Dimension.SetLoadFields(SystemId);
        if not Dimension.Get("Dimension Code") then
            exit(false);

        if DimensionId = Dimension.SystemId then
            exit(false);

        DimensionId := Dimension.SystemId;
        exit(true);
    end;

    local procedure UpdateDimensionValueId(): Boolean
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetLoadFields(SystemId);
        if DimensionValue.Get("Dimension Code", "Dimension Value Code") then begin
            if DimensionValueId = DimensionValue.SystemId then
                exit(false);

            DimensionValueId := DimensionValue.SystemId;
            exit(true);
        end;

        if "Dimension Value Code" = '' then begin
            if IsNullGuid(DimensionValueId) then
                exit(false);

            Clear(DimensionValueId);
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateReferencedIds()
    begin
        if UpdateReferencedIdFields() then
            Modify(false);
    end;

    procedure UpdateReferencedIdFields(): Boolean
    var
        Modified: Boolean;
    begin
        Modified := UpdateParentId();
        Modified := Modified or UpdateParentType();
        Modified := Modified or UpdateDimensionId();
        Modified := Modified or UpdateDimensionValueId();
        exit(Modified);
    end;

    local procedure ThrowEntityNotSupportedError(TableID: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableID);
        if AllObjWithCaption.FindFirst() then;
        Error(RequestedRecordIsNotSupportedErr, AllObjWithCaption."Object Caption");
    end;

    local procedure UpdateVendorTemplGlobalDimCode(GlobalDimCodeNo: Integer; VendorTemplCode: Code[20]; NewDimValue: Code[20])
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        if VendorTempl.Get(VendorTemplCode) then begin
            case GlobalDimCodeNo of
                1:
                    VendorTempl."Global Dimension 1 Code" := NewDimValue;
                2:
                    VendorTempl."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateVendorTemplGlobalDimCodeCaseElse(GlobalDimCodeNo, VendorTemplCode, NewDimValue);
            end;
            VendorTempl.Modify(true);
        end;
    end;

    local procedure UpdateCustomerTemplGlobalDimCode(GlobalDimCodeNo: Integer; CustomerTemplCode: Code[20]; NewDimValue: Code[20])
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        if CustomerTempl.Get(CustomerTemplCode) then begin
            case GlobalDimCodeNo of
                1:
                    CustomerTempl."Global Dimension 1 Code" := NewDimValue;
                2:
                    CustomerTempl."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateCustomerTemplGlobalDimCodeCaseElse(GlobalDimCodeNo, CustomerTemplCode, NewDimValue);
            end;
            CustomerTempl.Modify(true);
        end;
    end;

    local procedure UpdateItemTemplGlobalDimCode(GlobalDimCodeNo: Integer; ItemTemplCode: Code[20]; NewDimValue: Code[20])
    var
        ItemTempl: Record "Item Templ.";
    begin
        if ItemTempl.Get(ItemTemplCode) then begin
            case GlobalDimCodeNo of
                1:
                    ItemTempl."Global Dimension 1 Code" := NewDimValue;
                2:
                    ItemTempl."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateItemTemplGlobalDimCodeCaseElse(GlobalDimCodeNo, ItemTemplCode, NewDimValue);
            end;
            ItemTempl.Modify(true);
        end;
    end;

    local procedure UpdateEmployeeTemplGlobalDimCode(GlobalDimCodeNo: Integer; EmployeeTemplCode: Code[20]; NewDimValue: Code[20])
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if EmployeeTempl.Get(EmployeeTemplCode) then begin
            case GlobalDimCodeNo of
                1:
                    EmployeeTempl."Global Dimension 1 Code" := NewDimValue;
                2:
                    EmployeeTempl."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateEmployeeTemplGlobalDimCodeCaseElse(GlobalDimCodeNo, EmployeeTemplCode, NewDimValue);
            end;
            EmployeeTempl.Modify(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRangeToLastFieldInPrimaryKey(RecRef: RecordRef; Value: Code[20]; var FieldRef: FieldRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(DefaultDimension: Record "Default Dimension"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var DefaultDimension: Record "Default Dimension"; var DimensionManagement: Codeunit DimensionManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var DefaultDimension: Record "Default Dimension"; var DimensionManagement: Codeunit DimensionManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var DefaultDimension: Record "Default Dimension"; var DimensionManagement: Codeunit DimensionManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRename(var DefaultDimension: Record "Default Dimension"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGLAccGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; GLAccNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGLAccGlobalDimCodeOnBeforeGLAccModify(var GLAcc: Record "G/L Account"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBankGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; BankAccNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBankGlobalDimCodeOnBeforeBankModify(var BankAccount: Record "Bank Account"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCampaignGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; CampaignNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; CustNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustGlobalDimCodeOnBeforeCustModify(var Customer: Record Customer; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomerTemplGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; CustomerTemplCode: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEmpoyeeGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; EmployeeNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEmployeeGlobalDimCodeOnBeforeEmployeeModify(var Employee: Record Employee; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEmployeeTemplGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; EmployeeTemplCode: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFAGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; FANo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFAGlobalDimCodeOnBeforeFAModify(var FixedAsset: Record "Fixed Asset"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInsuranceGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; InsuranceNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInsuranceGlobalDimCodeOnBeforeInsuranceModify(var Insurance: Record Insurance; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; ItemNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemGlobalDimCodeOnBeforeItemModify(var Item: Record Item; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemTemplGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; ItemTemplCode: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateJobGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; JobNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateJobGlobalDimCodeOnBeforeJobModify(var Job: Record Job; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateNeutrRevGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; CFManualRevenueNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateNeutrPayGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; CFManualExpenseNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGrGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; ResGrNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGrGlobalDimCodeOnBeforeResGrModify(var ResGr: Record "Resource Group"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; ResNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResGlobalDimCodeOnBeforeResModify(var Resource: Record Resource; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRespCenterGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; RespCenterNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRespCenterGlobalDimCodeOnBeforeRespCenterModify(var RespCenter: Record "Responsibility Center"; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesPurchGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; SalespersonPurchaserNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendGlobalDimCodeOnCaseElse(GlobalDimCodeNo: Integer; VendNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendGlobalDimCodeOnBeforeVendModify(var Vend: Record Vendor; NewDimValue: Code[20]; GlobalDimCodeNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorTemplGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; VendorTemplCode: Code[20]; NewDimValue: Code[20])
    begin
    end;

#if not CLEAN26
    internal procedure RunOnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; WorkCenterNo: Code[20]; NewDimValue: Code[20])
    begin
        OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo, WorkCenterNo, NewDimValue);
    end;

    [Obsolete('Moved to codeunit Mfg. Dimension Management', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; WorkCenterNo: Code[20]; NewDimValue: Code[20])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRangeToLastFieldInPrimaryKey(RecRef: RecordRef; Value: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCaptionOnAfterAssignNewNo(NewTableID: Integer; SourceTableName: Text[250]; NewNo: Code[20]; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTableID(var RecDefaultDimension: Record "Default Dimension"; xRecDefaultDimension: Record "Default Dimension"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAllowedValuesFilter(var RecDefaultDimension: Record "Default Dimension"; xRecDefaultDimension: Record "Default Dimension"; var IsHandled: Boolean)
    begin
    end;
}

