// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

page 10753 "Recreate Missing SII Entries"
{
    Caption = 'Recreate Missing SII Entries';

    layout
    {
        area(content)
        {
            field(FromDate; FromDate)
            {
                ApplicationArea = All;
                Caption = 'From Date';
                ToolTip = 'Specifies the earliest posting date on entries that are analyzed for missing SII entries.';

                trigger OnValidate()
                begin
                    GetSourceEntries(false);
                end;
            }
            field(SomeEntriesAreNotConsideredMsg; SomeEntriesAreNotConsideredLbl)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                Visible = AllowRecreateAll;

                trigger OnDrillDown()
                begin
                    Message(EntriesToBeConsideredMsg);
                end;
            }
            field(ScanAllEntries; ScanAllEntriesLbl)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                Visible = AllowRecreateAll;

                trigger OnDrillDown()
                begin
                    GetSourceEntries(true);
                end;
            }
            group(Handle)
            {
                Caption = 'Handle';
                field(VendLedgEntryCount; TempVendorLedgerEntry.Count)
                {
                    ApplicationArea = All;
                    Caption = 'Invoices Received';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        TempDtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
                        VendLedgEntriesPreview: Page "Vend. Ledg. Entries Preview";
                    begin
                        VendLedgEntriesPreview.LookupMode(true);
                        VendLedgEntriesPreview.Set(TempVendorLedgerEntry, TempDtldVendorLedgEntry);
                        VendLedgEntriesPreview.Run();
                    end;
                }
                field(CustdLedgEntryCount; TempCustLedgEntry.Count)
                {
                    ApplicationArea = All;
                    Caption = 'Invoices Issued';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
                        CustLedgEntriesPreview: Page "Cust. Ledg. Entries Preview";
                    begin
                        CustLedgEntriesPreview.LookupMode(true);
                        CustLedgEntriesPreview.Set(TempCustLedgEntry, TempDtldCustLedgEntry);
                        CustLedgEntriesPreview.Run();
                    end;
                }
                field(DtldVendLedgEntryCount; TempDetailedVendorLedgEntry.Count)
                {
                    ApplicationArea = All;
                    Caption = 'Payments Issued';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        DetailedVendEntriesPreview: Page "Detailed Vend. Entries Preview";
                    begin
                        DetailedVendEntriesPreview.LookupMode(true);
                        DetailedVendEntriesPreview.Set(TempDetailedVendorLedgEntry);
                        DetailedVendEntriesPreview.Run();
                    end;
                }
                field(DtldCustLedgEntryCount; TempDetailedCustLedgEntry.Count)
                {
                    ApplicationArea = All;
                    Caption = 'Payments Received';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        DetCustLedgEntrPreview: Page "Det. Cust. Ledg. Entr. Preview";
                    begin
                        DetCustLedgEntrPreview.LookupMode(true);
                        DetCustLedgEntrPreview.Set(TempDetailedCustLedgEntry);
                        DetCustLedgEntrPreview.Run();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Start)
            {
                ApplicationArea = All;
                Caption = 'Start';
                Image = Start;
                ToolTip = 'Begin to recreate missing SII entries.';

                trigger OnAction()
                var
                    SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
                begin
                    SIIRecreateMissingEntries.UploadMissingSIIDocuments(
                      TempVendorLedgerEntry, TempCustLedgEntry, TempDetailedVendorLedgEntry, TempDetailedCustLedgEntry);
                    GetSourceEntries(false);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Start_Promoted; Start)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        SIISetup: Record "SII Setup";
        SIIMissingEntriesState: Record "SII Missing Entries State";
    begin
        if not SIISetup.IsEnabled() then
            Error(SIISetupNotEnabledErr);

        if not SIIMissingEntriesState.Get() then
            SIIMissingEntriesState.Init();
        FromDate := SIISetup."Starting Date";
        GetSourceEntries(SIIMissingEntriesState."Entries Missing" <> 0); // if missing entry was found by Job Queue Entry - run full scan
    end;

    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        FromDate: Date;
        SIISetupNotEnabledErr: Label 'The Enabled check box in the SII Setup window must be selected before you can recreate missing SII entries.';
        AllowRecreateAll: Boolean;
        SomeEntriesAreNotConsideredLbl: Label 'The entries that have already been scanned will be skipped. Learn why, and what to do.';
        EntriesToBeConsideredMsg: Label 'To speed up the scanning for missing SII entries, the entries that have already been scanned will be skipped.\\To scan all the entries from the starting date, choose Scan All Entries.';
        ScanAllEntriesLbl: Label 'Scan All Entries';

    local procedure GetSourceEntries(AllEntries: Boolean)
    var
        SIIMissingEntriesState: Record "SII Missing Entries State";
        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
    begin
        AllowRecreateAll := SIIMissingEntriesState.SIIEntryRecreated();
        SIIRecreateMissingEntries.GetSourceEntries(
          TempVendorLedgerEntry, TempCustLedgEntry, TempDetailedVendorLedgEntry, TempDetailedCustLedgEntry, AllEntries, FromDate);
    end;
}

