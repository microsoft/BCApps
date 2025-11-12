// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Team;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.Finance.Dimension;
using Microsoft.Integration.Dataverse;
using System.Email;

table 13 "Salesperson/Purchaser"
{
    Caption = 'Salesperson/Purchaser';
    DataCaptionFields = "Code", Name;
    DataClassification = CustomerContent;
    LookupPageID = "Salespersons/Purchasers";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField(Code);
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Commission %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Commission %';
            DecimalPlaces = 2 : 2;
            MaxValue = 100;
            MinValue = 0;
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
            ExtendedDatatype = Person;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dataverse';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dataverse';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Salesperson/Purchaser")));
        }
        field(5050; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(5051; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(5052; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
                SetSearchEmail();
            end;
        }
        field(5053; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(5054; "Next Task Date"; Date)
        {
            CalcFormula = min("To-do".Date where("Salesperson Code" = field(Code),
                                                  Closed = const(false),
                                                  "System To-do Type" = filter(Organizer | "Salesperson Attendee")));
            Caption = 'Next Task Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5055; "No. of Opportunities"; Integer)
        {
            CalcFormula = count("Opportunity Entry" where("Salesperson Code" = field(Code),
                                                           Active = const(true),
                                                           "Estimated Close Date" = field("Date Filter"),
                                                           "Action Taken" = field("Action Taken Filter"),
                                                           "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                           "Probability %" = field("Probability % Filter"),
                                                           "Completed %" = field("Completed % Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5056; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Estimated Value (LCY)" where("Salesperson Code" = field(Code),
                                                                                 Active = const(true),
                                                                                 "Estimated Close Date" = field("Date Filter"),
                                                                                 "Action Taken" = field("Action Taken Filter"),
                                                                                 "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                                                 "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                                                 "Probability %" = field("Probability % Filter"),
                                                                                 "Completed %" = field("Completed % Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5057; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Calcd. Current Value (LCY)" where("Salesperson Code" = field(Code),
                                                                                      Active = const(true),
                                                                                      "Estimated Close Date" = field("Date Filter"),
                                                                                      "Action Taken" = field("Action Taken Filter"),
                                                                                      "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                                                      "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                                                      "Probability %" = field("Probability % Filter"),
                                                                                      "Completed %" = field("Completed % Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5058; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5059; "No. of Interactions"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Salesperson Code" = field(Code),
                                                               Canceled = const(false),
                                                               Date = field("Date Filter"),
                                                               Postponed = const(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5060; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Interaction Log Entry"."Cost (LCY)" where("Salesperson Code" = field(Code),
                                                                          Canceled = const(false),
                                                                          Date = field("Date Filter"),
                                                                          Postponed = const(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5061; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Interaction Log Entry"."Duration (Min.)" where("Salesperson Code" = field(Code),
                                                                               Canceled = const(false),
                                                                               Date = field("Date Filter"),
                                                                               Postponed = const(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5062; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
        }
        field(5063; "Action Taken Filter"; Enum "Opportunity Action Taken")
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
        }
        field(5064; "Sales Cycle Filter"; Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(5065; "Sales Cycle Stage Filter"; Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage where("Sales Cycle Code" = field("Sales Cycle Filter"));
        }
        field(5066; "Probability % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Probability % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5067; "Completed % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Completed % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5068; "Avg. Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = average("Opportunity Entry"."Estimated Value (LCY)" where("Salesperson Code" = field(Code),
                                                                                     Active = const(true),
                                                                                     "Estimated Close Date" = field("Date Filter"),
                                                                                     "Action Taken" = field("Action Taken Filter"),
                                                                                     "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                                                     "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                                                     "Probability %" = field("Probability % Filter"),
                                                                                     "Completed %" = field("Completed % Filter")));
            Caption = 'Avg. Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5069; "Avg.Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = average("Opportunity Entry"."Calcd. Current Value (LCY)" where("Salesperson Code" = field(Code),
                                                                                          Active = const(true),
                                                                                          "Estimated Close Date" = field("Date Filter"),
                                                                                          "Action Taken" = field("Action Taken Filter"),
                                                                                          "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                                                          "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                                                          "Probability %" = field("Probability % Filter"),
                                                                                          "Completed %" = field("Completed % Filter")));
            Caption = 'Avg.Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5070; "Contact Filter"; Code[20])
        {
            Caption = 'Contact Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
        field(5071; "Contact Company Filter"; Code[20])
        {
            Caption = 'Contact Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact where(Type = const(Company));
        }
        field(5072; "Campaign Filter"; Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(5073; "Estimated Value Filter"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(5074; "Calcd. Current Value Filter"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(5075; "Chances of Success % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5076; "Task Status Filter"; Enum "Task Status")
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
        }
        field(5077; "Closed Task Filter"; Boolean)
        {
            Caption = 'Closed Task Filter';
            FieldClass = FlowFilter;
        }
        field(5078; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(5079; "Team Filter"; Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(5082; "Opportunity Entry Exists"; Boolean)
        {
            CalcFormula = exist("Opportunity Entry" where("Salesperson Code" = field(Code),
                                                           Active = const(true),
                                                           "Contact No." = field("Contact Filter"),
                                                           "Contact Company No." = field("Contact Company Filter"),
                                                           "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                           "Campaign No." = field("Campaign Filter"),
                                                           "Action Taken" = field("Action Taken Filter"),
                                                           "Estimated Value (LCY)" = field("Estimated Value Filter"),
                                                           "Calcd. Current Value (LCY)" = field("Calcd. Current Value Filter"),
                                                           "Completed %" = field("Completed % Filter"),
                                                           "Chances of Success %" = field("Chances of Success % Filter"),
                                                           "Probability %" = field("Probability % Filter"),
                                                           "Estimated Close Date" = field("Date Filter"),
                                                           "Close Opportunity Code" = field("Close Opportunity Filter")));
            Caption = 'Opportunity Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5083; "Task Entry Exists"; Boolean)
        {
            CalcFormula = exist("To-do" where("Salesperson Code" = field(Code),
                                               "Contact No." = field("Contact Filter"),
                                               "Contact Company No." = field("Contact Company Filter"),
                                               "Campaign No." = field("Campaign Filter"),
                                               "Team Code" = field("Team Filter"),
                                               Status = field("Task Status Filter"),
                                               Closed = field("Closed Task Filter"),
                                               Priority = field("Priority Filter"),
                                               Date = field("Date Filter")));
            Caption = 'Task Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5084; "Close Opportunity Filter"; Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(5085; "Search E-Mail"; Code[80])
        {
            Caption = 'Search Email';
        }
        field(5086; "E-Mail 2"; Text[80])
        {
            Caption = 'Email 2';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail 2");
            end;
        }
        field(5087; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Search E-Mail")
        {
        }
        key(Key3; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
        fieldgroup(Brick; "Code", Name, Image)
        {
        }
    }

    trigger OnDelete()
    var
        TeamSalesperson: Record "Team Salesperson";
        TodoTask: Record "To-do";
        Opportunity: Record Opportunity;
    begin
        TodoTask.Reset();
        TodoTask.SetCurrentKey("Salesperson Code", Closed);
        TodoTask.SetRange("Salesperson Code", Code);
        TodoTask.SetRange(Closed, false);
        if not TodoTask.IsEmpty() then
            Error(CannotDeleteBecauseActiveTasksErr, Code);

        Opportunity.SetRange("Salesperson Code", Code);
        Opportunity.SetRange(Closed, false);
        if not Opportunity.IsEmpty() then
            Error(CannotDeleteBecauseActiveOpportunitiesErr, Code);

        TeamSalesperson.Reset();
        TeamSalesperson.SetRange("Salesperson Code", Code);
        TeamSalesperson.DeleteAll();
        DimMgt.DeleteDefaultDim(DATABASE::"Salesperson/Purchaser", Code);
    end;

    trigger OnInsert()
    begin
        Validate(Code);
        SetSearchEmail();
        DimMgt.UpdateDefaultDim(
          DATABASE::"Salesperson/Purchaser", Code,
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        Validate(Code);
        SetSearchEmail();
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Salesperson/Purchaser", xRec.Code, Code);
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        PostActionTxt: Label 'post';
        CreateActionTxt: Label 'create';
        SalespersonTxt: Label 'Salesperson';
        PurchaserTxt: Label 'Purchaser';
        CannotDeleteBecauseActiveTasksErr: Label 'You cannot delete the salesperson/purchaser with code %1 because it has open tasks.', Comment = '%1 = Salesperson/Purchaser code.';
        BlockedSalesPersonPurchErr: Label 'You cannot %1 this document because %2 %3 is blocked due to privacy.', Comment = '%1 = post or create, %2 = Salesperson / Purchaser, %3 = salesperson / purchaser code.';
        PrivacyBlockedGenericTxt: Label 'Privacy Blocked must not be true for %1 %2.', Comment = '%1 = Salesperson / Purchaser, %2 = salesperson / purchaser code.';
        CannotDeleteBecauseActiveOpportunitiesErr: Label 'You cannot delete the salesperson/purchaser with code %1 because it has open opportunities.', Comment = '%1 = Salesperson/Purchaser code.';

    procedure CreateInteraction()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        TempSegmentLine.CreateInteractionFromSalesperson(Rec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Salesperson/Purchaser", Code, FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure GetPrivacyBlockedTransactionText(SalespersonPurchaser2: Record "Salesperson/Purchaser"; IsPostAction: Boolean; IsSalesperson: Boolean): Text[150]
    var
        "Action": Text[30];
        Type: Text[20];
    begin
        if IsPostAction then
            Action := PostActionTxt
        else
            Action := CreateActionTxt;
        if IsSalesperson then
            Type := SalespersonTxt
        else
            Type := PurchaserTxt;
        exit(StrSubstNo(BlockedSalesPersonPurchErr, Action, Type, SalespersonPurchaser2.Code));
    end;

    procedure GetPrivacyBlockedGenericText(SalespersonPurchaser2: Record "Salesperson/Purchaser"; IsSalesperson: Boolean): Text[150]
    var
        Type: Text[20];
    begin
        if IsSalesperson then
            Type := SalespersonTxt
        else
            Type := PurchaserTxt;
        exit(StrSubstNo(PrivacyBlockedGenericTxt, Type, SalespersonPurchaser2.Code));
    end;

    procedure VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser2: Record "Salesperson/Purchaser"): Boolean
    begin
        if SalespersonPurchaser2."Privacy Blocked" then
            exit(true);
        exit(false);
    end;

    local procedure SetSearchEmail()
    begin
        if "Search E-Mail" <> "E-Mail".ToUpper() then
            "Search E-Mail" := "E-Mail";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var xSalespersonPurchaser: Record "Salesperson/Purchaser"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var xSalespersonPurchaser: Record "Salesperson/Purchaser"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}
