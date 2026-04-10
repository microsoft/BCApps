// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

using Microsoft.Foundation.NoSeries;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Request;
using System.Utilities;

table 5769 "Warehouse Setup"
{
    Caption = 'Warehouse Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Warehouse Setup";
    LookupPageID = "Warehouse Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Whse. Receipt Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Receipt Header" = R;
            Caption = 'Whse. Receipt Nos.';
            ToolTip = 'Specifies the number series code to use when you assign numbers to warehouse receipt journals.';
            TableRelation = "No. Series";
        }
        field(3; "Whse. Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Whse. Put-away Nos.';
            ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse put-away documents.';
            TableRelation = "No. Series";
        }
        field(5; "Whse. Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Whse. Pick Nos.';
            ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse pick documents.';
            TableRelation = "No. Series";
        }
        field(6; "Whse. Ship Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Whse. Ship Nos.';
            ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse shipment journals.';
            TableRelation = "No. Series";
        }
        field(7; "Registered Whse. Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Registered Whse. Pick Nos.';
            ToolTip = 'Specifies the number series code you want to be used to assign numbers to registered pick documents.';
            TableRelation = "No. Series";
        }
        field(10; "Registered Whse. Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Registered Whse. Put-away Nos.';
            ToolTip = 'Specifies the number series code used when numbers are assigned to registered put-away documents.';
            TableRelation = "No. Series";
        }
        field(13; "Require Receive"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Receipt Header" = R;
            Caption = 'Require Receive';
            ToolTip = 'Specifies whether you require users to use the receive activity.';

            trigger OnValidate()
            begin
                if not "Require Receive" then
                    "Require Put-away" := false
                else
                    ConfirmDiscontinuedFieldBeingSet(Rec.FieldCaption("Require Receive"), Rec.TableCaption);
            end;
        }
        field(14; "Require Put-away"; Boolean)
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Require Put-away';
            ToolTip = 'Specifies whether you require users to use the put-away activity.';

            trigger OnValidate()
            begin
                if "Require Put-away" then begin
                    ConfirmDiscontinuedFieldBeingSet(Rec.FieldCaption("Require Put-away"), Rec.TableCaption);
                    "Require Receive" := true;
                end;

            end;
        }
        field(15; "Require Pick"; Boolean)
        {
            AccessByPermission = TableData "Posted Invt. Pick Header" = R;
            Caption = 'Require Pick';
            ToolTip = 'Specifies whether you require users to use the pick activity.';

            trigger OnValidate()
            begin
                if "Require Pick" then begin
                    ConfirmDiscontinuedFieldBeingSet(Rec.FieldCaption("Require Pick"), Rec.TableCaption);
                    "Require Shipment" := true;
                end;
            end;
        }
        field(16; "Require Shipment"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Require Shipment';
            ToolTip = 'Specifies if warehouse shipments are required in warehouse work flows.';

            trigger OnValidate()
            begin
                if not "Require Shipment" then
                    "Require Pick" := false
                else
                    ConfirmDiscontinuedFieldBeingSet(Rec.FieldCaption("Require Shipment"), Rec.TableCaption);
            end;
        }
#if not CLEANSCHEMA28
        field(17; "Last Whse. Posting Ref. No."; Integer)
        {
            Caption = 'Last Whse. Posting Ref. No.';
            Editable = false;
            ObsoleteReason = 'Replaced by Last Whse. Posting Ref. Seq. field.';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
        field(18; "Receipt Posting Policy"; Option)
        {
            Caption = 'Receipt Posting Policy';
            ToolTip = 'Specifies what should happen if errors occur when warehouse receipts are posted.';
            OptionCaption = 'Posting errors are not processed,Stop and show the first posting error';
            OptionMembers = "Posting errors are not processed","Stop and show the first posting error";
            InitValue = "Stop and show the first posting error";
        }
        field(19; "Shipment Posting Policy"; Option)
        {
            Caption = 'Shipment Posting Policy';
            ToolTip = 'Specifies what should happen if errors occur when warehouse shipments are posted per source document.';
            OptionCaption = 'Posting errors are not processed,Stop and show the first posting error';
            OptionMembers = "Posting errors are not processed","Stop and show the first posting error";
            InitValue = "Stop and show the first posting error";
        }
        field(20; "Last Whse. Posting Ref. Seq."; Code[40])
        {
            Caption = 'Last Whse. Posting Ref. Seq.';
            Editable = false;
        }
        field(51; "Copy Item Descr. to Entries"; Boolean)
        {
            Caption = 'Copy Item Descr. to Entries';
            ToolTip = 'Specifies if you want the description on item cards to be copied to warehouse entries during registering.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                UpdateNameInLedgerEntries: Codeunit Microsoft.Upgrade."Update Name In Ledger Entries";
            begin
                if Rec."Copy Item Descr. to Entries" then
                    UpdateNameInLedgerEntries.NotifyAboutBlankNamesInLedgerEntries(RecordId);
            end;
        }
        field(7301; "Posted Whse. Receipt Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Receipt Header" = R;
            Caption = 'Posted Whse. Receipt Nos.';
            ToolTip = 'Specifies the number series code used to assign numbers to posted warehouse receipts.';
            TableRelation = "No. Series";
        }
        field(7303; "Posted Whse. Shipment Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Posted Whse. Shipment Nos.';
            ToolTip = 'Specifies the number series code used to assign numbers to posted warehouse shipments.';
            TableRelation = "No. Series";
        }
        field(7304; "Whse. Internal Put-away Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Whse. Internal Put-away Nos.';
            ToolTip = 'Specifies the number series code used to assign numbers to internal put-always.';
            TableRelation = "No. Series";
        }
        field(7306; "Whse. Internal Pick Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Whse. Internal Pick Nos.';
            ToolTip = 'Specifies the number series code used to assign numbers to internal picks.';
            TableRelation = "No. Series";
        }
        field(7308; "Whse. Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Whse. Movement Nos.';
            ToolTip = 'Specifies the number series code used to assign numbers to warehouse movements.';
            TableRelation = "No. Series";
        }
        field(7309; "Registered Whse. Movement Nos."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Registered Whse. Movement Nos.';
            ToolTip = 'Specifies the number series code used to assign numbers to registered warehouse movements.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecordHasBeenRead: Boolean;
        SetDiscontinuedFieldQst: Label 'The %1 field will be removed from %2 in a future release. Use the %1 field for a specific location instead. \\Do you want to continue?', Comment = '%1 = field name, %2 = table name.';
        SetDiscontinuedFieldTelemetryMsg: Label 'The %1 field was enabled on %2 in company %3.', Comment = '%1 = field name, %2 = table name, %3 = company name';
        TelemetryCategoryLbl: Label 'AL Warehouse Setup', Locked = true;


    local procedure ConfirmDiscontinuedFieldBeingSet(Field_Caption: Text; Table_Caption: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(SetDiscontinuedFieldQst, Field_Caption, Table_Caption), false) then
            Error('')
        else
            Session.LogMessage('0000JR8', StrSubstNo(SetDiscontinuedFieldTelemetryMsg, Field_Caption, Table_Caption, CompanyName), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryLbl);
    end;

    procedure GetCurrentReference(): Integer
    begin
        Rec.Get();
        EnsureSequenceExists();
        exit(NumberSequence.Current(Rec."Last Whse. Posting Ref. Seq.") mod MaxInt());
    end;

    procedure GetNextReference(): Integer
    begin
        EnsureSequenceExists();
        exit(NumberSequence.Next(Rec."Last Whse. Posting Ref. Seq.") mod MaxInt());
    end;

    local procedure EnsureSequenceExists()
    begin
        Rec.Get();
        if Rec."Last Whse. Posting Ref. Seq." = '' then begin
            LockTable();
            Get();
            if Rec."Last Whse. Posting Ref. Seq." = '' then begin
                Rec."Last Whse. Posting Ref. Seq." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Rec."Last Whse. Posting Ref. Seq."));
                Rec."Last Whse. Posting Ref. Seq." := DelChr(Rec."Last Whse. Posting Ref. Seq.", '=', '{}');
                Modify();
            end;
        end;
        if NumberSequence.Exists("Last Whse. Posting Ref. Seq.") then
            exit;
        NumberSequence.Insert(Rec."Last Whse. Posting Ref. Seq.", 0, 1);
        // Simulate that a number was used - init issue with number sequences.
        if NumberSequence.next(Rec."Last Whse. Posting Ref. Seq.") = 0 then;
    end;

    local procedure MaxInt(): Integer
    begin
        exit(2147483647);
    end;

#if not CLEAN27
    [Obsolete('This function is deprecated. Concurrent warehouse posting is always on.', '27.0')]
    procedure UseLegacyPosting(): Boolean
    begin
        exit(false);
    end;
#endif

    internal procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;
}
