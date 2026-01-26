// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using System.Utilities;

report 28001 "BarCode Batch Job"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BarCode Batch Job';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                Window.Open(Text1500001);
                if CheckMasterCard then begin
                    BrowseTable(14, 0, 5701, 5702, 5703, 5714, 5720);
                    BrowseTable(18, 0, 5, 6, 7, 91, 35);
                    BrowseTable(23, 0, 5, 6, 7, 91, 35);
                    BrowseTable(79, 0, 4, 5, 6, 30, 36);
                    BrowseTable(79, 2, 24, 25, 26, 32, 37);
                    BrowseTable(156, 0, 6, 7, 8, 53, 59);
                    BrowseTable(222, 0, 5, 6, 7, 91, 35);
                    BrowseTable(224, 0, 5, 6, 7, 91, 35);
                    BrowseTable(270, 0, 5, 6, 7, 91, 35);
                    BrowseTable(287, 0, 6, 7, 8, 9, 17);
                    BrowseTable(288, 0, 6, 7, 8, 9, 17);
                    BrowseTable(5200, 0, 8, 9, 10, 11, 25);
                    BrowseTable(5201, 0, 5, 6, 7, 8, 14);
                    BrowseTable(5209, 0, 3, 9, 5, 4, 14);
                    BrowseTable(5714, 0, 3, 4, 5, 6, 7);
                end;
                if CheckContactCard then begin
                    BrowseTable(5050, 0, 5, 6, 7, 91, 35);
                    BrowseTable(5051, 0, 5, 6, 7, 8, 10);
                end;
                if CheckDocument then begin
                    BrowseTable(36, 1, 7, 8, 9, 85, 87);
                    BrowseTable(36, 2, 15, 16, 17, 91, 93);
                    BrowseTable(36, 3, 81, 82, 83, 88, 90);
                    BrowseTable(38, 4, 7, 8, 9, 85, 87);
                    BrowseTable(38, 2, 15, 16, 17, 91, 93);
                    BrowseTable(38, 5, 81, 82, 83, 88, 90);
                    BrowseTable(295, 0, 5, 6, 8, 7, 10);
                    BrowseTable(302, 0, 5, 6, 8, 7, 10);
                    BrowseTable(5740, 6, 5, 6, 8, 7, 10);
                    BrowseTable(5740, 7, 14, 15, 17, 16, 19);
                    BrowseTable(5900, 0, 11, 12, 14, 13, 86);
                    BrowseTable(5900, 1, 44, 45, 47, 46, 88);
                    BrowseTable(5900, 2, 51, 52, 54, 53, 90);
                end;
                Window.Close();
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
                Text1240001: Label 'You must specify an %1 in %2.';
            begin
                GLSetup.Get();
                if GLSetup."AMAS Software" = 0 then
                    Error(Text1240001, GLSetup.FieldCaption("AMAS Software"), GLSetup.TableCaption());
                AddressID.LockTable();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CheckMasterCard; CheckMasterCard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Master Cards';
                        ToolTip = 'Specifies that you want to verify addresses for master data.';
                    }
                    field(CheckContactCard; CheckContactCard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Contact Cards';
                        ToolTip = 'Specifies that you want to verify addresses for contacts.';
                    }
                    field(CheckDocument; CheckDocument)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Documents';
                        ToolTip = 'Specifies that you want to verify addresses on documents.';
                    }
                    field(CheckExistingAddressID; CheckExistingAddressID)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Existing Package Sequence No.';
                        ToolTip = 'Specifies that you want to also verify the package sequence numbers.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text1500001: Label 'Checking Table No.    #1######\Checking Address Type #2######\\@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
        AddressID: Record "Address ID";
        CheckMasterCard: Boolean;
        CheckContactCard: Boolean;
        CheckDocument: Boolean;
        CheckExistingAddressID: Boolean;
        Window: Dialog;

    local procedure BrowseTable(TableNo: Integer; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; AddressFieldNo: Integer; Address2FieldNo: Integer; CityFieldNo: Integer; PostCodeFieldNo: Integer; CountryCodeFieldNo: Integer)
    var
        PostCodeCheck: Codeunit "Post Code Check";
        RecordRef: RecordRef;
        AddressFieldRef: FieldRef;
        Address2FieldRef: FieldRef;
        CityFieldRef: FieldRef;
        PostCodeFieldRef: FieldRef;
        CountryCodeFieldRef: FieldRef;
        TotalRec: Integer;
        CurrentRec: Integer;
        SkipRec: Boolean;
        Name: Text[100];
        Name2: Text[50];
        Contact: Text[100];
        Address: Text[100];
        Address2: Text[50];
        City: Text[30];
        PostCode: Code[20];
        County: Text[30];
        CountryCode: Code[10];
    begin
        Window.Update(1, TableNo);
        Window.Update(2, AddressType);
        RecordRef.Open(TableNo);
        TotalRec := RecordRef.Count();
        CurrentRec := 1;
        AddressFieldRef := RecordRef.Field(AddressFieldNo);
        Address2FieldRef := RecordRef.Field(Address2FieldNo);
        CityFieldRef := RecordRef.Field(CityFieldNo);
        PostCodeFieldRef := RecordRef.Field(PostCodeFieldNo);
        CountryCodeFieldRef := RecordRef.Field(CountryCodeFieldNo);
        if RecordRef.Find('-') then
            repeat
                SkipRec := false;
                Window.Update(3, Round((CurrentRec / TotalRec) * 10000, 1));
                Address := Format(AddressFieldRef.Value);
                Address2 := Format(Address2FieldRef.Value);
                City := Format(CityFieldRef.Value);
                PostCode := Format(PostCodeFieldRef.Value);
                PostCodeCheck.VerifyAddress(1, TableNo, RecordRef.GetPosition(), AddressType,
                    Name,
                    Name2,
                    Contact,
                    Address,
                    Address2,
                    City,
                    PostCode,
                    County,
                    CountryCode);
                CurrentRec := CurrentRec + 1;
            until RecordRef.Next() = 0;

        RecordRef.Close();
    end;

}

