// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Campaign;

using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.NoSeries;
using Microsoft.Pricing.Source;
using System.Security.User;

table 5071 Campaign
{
    Caption = 'Campaign';
    DataCaptionFields = "No.", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Campaign List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    RMSetup.Get();
                    NoSeries.TestManual(RMSetup."Campaign Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" > 0D) then
                    Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
            end;
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if ("Ending Date" < "Starting Date") and ("Ending Date" > 0D) then
                    Error(Text001, FieldCaption("Ending Date"), FieldCaption("Starting Date"));
            end;
        }
        field(5; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(6; Comment; Boolean)
        {
            CalcFormula = exist("Rlshp. Mgt. Comment Line" where("Table Name" = const(Campaign),
                                                                  "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(8; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(9; "Global Dimension 1 Code"; Code[20])
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
        field(10; "Global Dimension 2 Code"; Code[20])
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
        field(11; "Status Code"; Code[10])
        {
            Caption = 'Status Code';
            TableRelation = "Campaign Status";
        }
        field(12; "Target Contacts Contacted"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Campaign No." = field("No."),
                                                               "Campaign Target" = const(true),
                                                               Canceled = const(false),
                                                               Date = field("Date Filter"),
                                                               Postponed = const(false)));
            Caption = 'Target Contacts Contacted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Contacts Responded"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Campaign No." = field("No."),
                                                               "Campaign Response" = const(true),
                                                               Canceled = const(false),
                                                               Date = field("Date Filter"),
                                                               Postponed = const(false)));
            Caption = 'Contacts Responded';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Interaction Log Entry"."Duration (Min.)" where("Campaign No." = field("No."),
                                                                               Canceled = const(false),
                                                                               Date = field("Date Filter"),
                                                                               Postponed = const(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Interaction Log Entry"."Cost (LCY)" where("Campaign No." = field("No."),
                                                                          Canceled = const(false),
                                                                          Date = field("Date Filter"),
                                                                          Postponed = const(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "No. of Opportunities"; Integer)
        {
            CalcFormula = count("Opportunity Entry" where("Campaign No." = field("No."),
                                                           Active = const(true)));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Estimated Value (LCY)" where("Campaign No." = field("No."),
                                                                                 Active = const(true)));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Calcd. Current Value (LCY)" where("Campaign No." = field("No."),
                                                                                      Active = const(true)));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(23; "Action Taken Filter"; Enum "Opportunity Action Taken")
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
        }
        field(24; "Sales Cycle Filter"; Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(25; "Sales Cycle Stage Filter"; Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage where("Sales Cycle Code" = field("Sales Cycle Filter"));
        }
        field(26; "Probability % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Probability % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(27; "Completed % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Completed % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(28; "Contact Filter"; Code[20])
        {
            Caption = 'Contact Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
        field(29; "Contact Company Filter"; Code[20])
        {
            Caption = 'Contact Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact where(Type = const(Company));
        }
        field(30; "Estimated Value Filter"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(31; "Calcd. Current Value Filter"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(32; "Chances of Success % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(33; "Task Status Filter"; Enum "Task Status")
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
        }
        field(34; "Task Closed Filter"; Boolean)
        {
            Caption = 'Task Closed Filter';
            FieldClass = FlowFilter;
        }
        field(35; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(36; "Team Filter"; Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(37; "Salesperson Filter"; Code[20])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(38; "Opportunity Entry Exists"; Boolean)
        {
            CalcFormula = exist("Opportunity Entry" where("Campaign No." = field("No."),
                                                           Active = const(true),
                                                           "Salesperson Code" = field("Salesperson Filter"),
                                                           "Contact No." = field("Contact Filter"),
                                                           "Contact Company No." = field("Contact Company Filter"),
                                                           "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
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
        field(39; "Task Entry Exists"; Boolean)
        {
            CalcFormula = exist("To-do" where("Campaign No." = field("No."),
                                               "Contact No." = field("Contact Filter"),
                                               "Contact Company No." = field("Contact Company Filter"),
                                               "Salesperson Code" = field("Salesperson Filter"),
                                               "Team Code" = field("Team Filter"),
                                               Status = field("Task Status Filter"),
                                               Closed = field("Task Closed Filter"),
                                               Priority = field("Priority Filter"),
                                               Date = field("Date Filter")));
            Caption = 'Task Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Close Opportunity Filter"; Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(41; Activated; Boolean)
        {
            CalcFormula = exist("Campaign Target Group" where("Campaign No." = field("No.")));
            Caption = 'Activated';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Salesperson Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Starting Date", "Ending Date", "Status Code")
        {
        }
    }

    trigger OnDelete()
    begin
        DimMgt.DeleteDefaultDim(DATABASE::Campaign, "No.");

        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::Campaign);
        RMCommentLine.SetRange("No.", "No.");
        RMCommentLine.DeleteAll();

        CampaignEntry.SetCurrentKey("Campaign No.");
        CampaignEntry.SetRange("Campaign No.", "No.");
        CampaignEntry.DeleteAll();

        CampaignMgmt.DeactivateCampaign(Rec, false);
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            RMSetup.Get();
            RMSetup.TestField("Campaign Nos.");
            if NoSeries.AreRelated(RMSetup."Campaign Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := RMSetup."Campaign Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        if "Salesperson Code" = '' then
            SetDefaultSalesperson();

        DimMgt.UpdateDefaultDim(
          DATABASE::Campaign, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::Campaign, xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Campaign, xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        RMSetup: Record "Marketing Setup";
        Campaign: Record Campaign;
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        CampaignEntry: Record "Campaign Entry";
        CommentLine: Record "Comment Line";
        NoSeries: Codeunit "No. Series";
        DimMgt: Codeunit DimensionManagement;
        CampaignMgmt: Codeunit "Campaign Target Group Mgt";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be before %2.';
        Text001: Label '%1 must be after %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AssistEdit(OldCampaign: Record Campaign): Boolean
    begin
        Campaign := Rec;
        RMSetup.Get();
        RMSetup.TestField("Campaign Nos.");
        if NoSeries.LookupRelatedNoSeries(RMSetup."Campaign Nos.", OldCampaign."No. Series", Campaign."No. Series") then begin
            Campaign."No." := NoSeries.GetNextNo(Campaign."No. Series");
            Rec := Campaign;
            exit(true);
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Campaign, "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        if UserSetup."Salespers./Purch. Code" <> '' then
            Validate("Salesperson Code", UserSetup."Salespers./Purch. Code");
    end;

    procedure ToPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceSource."Price Type"::Sale;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Campaign);
        PriceSource.Validate("Source No.", "No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(Campaign: Record Campaign; xCampaign: Record Campaign; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(Campaign: Record Campaign; xCampaign: Record Campaign; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}
