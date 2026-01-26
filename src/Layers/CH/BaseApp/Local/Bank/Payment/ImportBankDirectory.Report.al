// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Utilities;

report 11504 "Import Bank Directory"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/ImportBankDirectory.rdlc';
    Caption = 'Import Bank Directory';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ReadRec; ReadRec)
            {
            }
            column(BankDirectoryTableCaption; BankDirectory.TableCaption())
            {
            }
            column(WriteRec; WriteRec)
            {
            }
            column(ImportText; ImportText)
            {
            }
            column(FileName; FileName)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ImportBankDirectoryCaption; ImportBankDirectoryCaptionLbl)
            {
            }
            dataitem("Customer Bank Account"; "Customer Bank Account")
            {
                DataItemTableView = sorting("Customer No.", Code) order(ascending) where("Bank Branch No." = filter(<> ''));
                column(CustomerBankAccountTableCaption; "Customer Bank Account".TableCaption())
                {
                }
                column(CustomerNo_CustomerBankAccount; "Customer No.")
                {
                }
                column(Code_CustomerBankAccount; Code)
                {
                }
                column(OldBranchNo; OldBranchNo)
                {
                }
                column(BankBranchNo_CustomerBankAccount; "Bank Branch No.")
                {
                }
                column(BranchNotFound; BranchNotFound)
                {
                }
                column(OldBankBranchNoCaption; OldBankBranchNoCaptionLbl)
                {
                }
                column(CodeCaption_CustomerBankAccount; FieldCaption(Code))
                {
                }
                column(CustomerNoCaption_CustomerBankAccount; FieldCaption("Customer No."))
                {
                }
                column(NewBankBranchNoCaption; NewBankBranchNoCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    OldBranchNo := '';
                    BranchNotFound := '';

                    if not BankDirectory.Get("Bank Branch No.") then
                        BranchNotFound := StrSubstNo(Text005, "Bank Branch No.", BankDirectory.TableCaption())
                    else
                        if BankDirectory."New Clearing No." <> '' then begin
                            OldBranchNo := "Bank Branch No.";
                            Validate("Bank Branch No.", BankDirectory."New Clearing No.");
                            if AutoUpdate then
                                Modify();
                        end else
                            CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    BankDirectory.Reset();
                end;
            }
            dataitem("Vendor Bank Account"; "Vendor Bank Account")
            {
                DataItemTableView = sorting("Vendor No.", Code) order(ascending) where("Clearing No." = filter(<> ''));
                column(VendorBankAccountTableCaption; "Vendor Bank Account".TableCaption())
                {
                }
                column(VendorNo_VendorBankAccount; "Vendor No.")
                {
                }
                column(Code_VendorBankAccount; "Vendor Bank Account".Code)
                {
                }
                column(ClearingNo_VendorBankAccount; "Vendor Bank Account"."Clearing No.")
                {
                }
                column(ClearingNo_VendorBankAccount2; VendorBankAccount2."Clearing No.")
                {
                }
                column(BranchNotFound_VendorBankAccount; BranchNotFound)
                {
                }
                column(VendorBankAccount2Code; VendorBankAccount2.Code)
                {
                }
                column(VendorNoCaption_VendorBankAccount; FieldCaption("Vendor No."))
                {
                }
                column(OldCodeCaption; OldCodeCaptionLbl)
                {
                }
                column(OldClearingNoCaption; OldClearingNoCaptionLbl)
                {
                }
                column(NewClearingNoCaption; NewClearingNoCaptionLbl)
                {
                }
                column(NewCodeCaption; NewCodeCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    OldBranchNo := '';
                    BranchNotFound := '';

                    if not BankDirectory.Get("Clearing No.") then
                        BranchNotFound := StrSubstNo(Text005, "Clearing No.", BankDirectory.TableCaption())
                    else
                        if BankDirectory."New Clearing No." <> '' then begin
                            VendorBankAccount2.SetRange("Vendor No.", "Vendor No.");
                            VendorBankAccount2.SetRange("Clearing No.", BankDirectory."New Clearing No.");
                            if not VendorBankAccount2.Find('-') then begin
                                VendorBankAccount2.Reset();
                                VendorBankAccount2.Init();
                                VendorBankAccount2.TransferFields("Vendor Bank Account");
                                VendorBankAccount2.Code := Format(Code + BankDirectory."New Clearing No.", -10);
                                VendorBankAccount2.Validate("Clearing No.", BankDirectory."New Clearing No.");
                                if AutoUpdate then
                                    if not VendorBankAccount2.Insert() then
                                        BranchNotFound := StrSubstNo(Text007, "Vendor No.", Code);
                            end else
                                CurrReport.Skip();
                        end else
                            CurrReport.Skip();
                end;
            }
            dataitem(Other; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(OtherText; OtherText)
                {
                }
                column(OtherCaption; OtherCaptionLbl)
                {
                }
                column(TableCaptionOther; TableCaptionLbl)
                {
                }
                column(FieldCaption; FieldCaptionLbl)
                {
                }
                column(BankDirectoryNewClearingNoCaption; NewClearingNoCaptionLbl)
                {
                }
                column(EntryCaption; EntryCaptionLbl)
                {
                }
                dataitem("DTA Setup"; "DTA Setup")
                {
                    DataItemTableView = sorting("Bank Code") order(ascending) where("DTA Sender Clearing" = filter(<> ''));
                    column(TableCaption_DTASetup; TableCaption)
                    {
                    }
                    column(DTASenderClearing_DTASetup; FieldCaption("DTA Sender Clearing"))
                    {
                    }
                    column(BankDirectoryNewClearingNo; BankDirectory."New Clearing No.")
                    {
                    }
                    column(DTASetupBranchNotFound; BranchNotFound)
                    {
                    }
                    column(DTASetupBankCode; "Bank Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        OldBranchNo := '';
                        BranchNotFound := '';

                        if not BankDirectory.Get("DTA Sender Clearing") then
                            BranchNotFound := StrSubstNo(Text005, "DTA Sender Clearing", BankDirectory.TableCaption())
                        else
                            if BankDirectory."New Clearing No." = '' then
                                CurrReport.Skip();
                    end;
                }
                dataitem("LSV Setup"; "LSV Setup")
                {
                    DataItemTableView = sorting("Bank Code") order(ascending) where("LSV Sender Clearing" = filter(<> ''));
                    column(LSVSetupTableCaption; TableCaption)
                    {
                    }
                    column(LSVSenderClearingCaption; FieldCaption("LSV Sender Clearing"))
                    {
                    }
                    column(BankDirectoryNewClearingNo_LSVSetup; BankDirectory."New Clearing No.")
                    {
                    }
                    column(BranchNotFoundLSVSetup; BranchNotFound)
                    {
                    }
                    column(BankCode_LSVSetup; "Bank Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        OldBranchNo := '';
                        BranchNotFound := '';

                        if not BankDirectory.Get("LSV Sender Clearing") then
                            BranchNotFound := StrSubstNo(Text005, "LSV Sender Clearing", BankDirectory.TableCaption())
                        else
                            if BankDirectory."New Clearing No." = '' then
                                CurrReport.Skip();
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if AutoUpdate then
                        OtherText := Text006;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ReadRec := StrSubstNo(Text001, NoOfRecsRead);
                WriteRec := StrSubstNo(Text002, NoOfRecsWritten);

                if AutoUpdate then
                    ImportText := Text004
                else
                    ImportText := Text003;
            end;

            trigger OnPreDataItem()
            begin
                if FileName <> '' then
                    BankDirectory.ImportBankDirectoryFromTempBlob(TempBlob, NoOfRecsRead, NoOfRecsWritten);
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
                    field(FileName; FileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the name of the file to be imported.';

                        trigger OnAssistEdit()
                        var
                            IsHandled: Boolean;
                        begin
                            OnImportFile(TempBlob, FileName, IsHandled);
                            if IsHandled then
                                exit;
                            FileName := FileMgt.BLOBImportWithFilter(TempBlob, Text009, FileName, Text008, '*.*')
                        end;
                    }
                    field(AutoUpdate; AutoUpdate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Automatically update Clearing Numbers';
                        MultiLine = true;
                        ToolTip = 'Specifies that the bank clearing numbers are automatically updated as they are imported.';
                    }
                    label(Control1150000)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19057439;
                        ShowCaption = false;
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
        BankDirectory: Record "Bank Directory";
        VendorBankAccount2: Record "Vendor Bank Account";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        NoOfRecsRead: Integer;
        NoOfRecsWritten: Integer;
        AutoUpdate: Boolean;
        FileName: Text;
        ReadRec: Text[80];
        WriteRec: Text[80];
        ImportText: Text[80];
        BranchNotFound: Text[80];
        OldBranchNo: Code[20];
        OtherText: Text[100];
        Text001: Label '%1 Records have been imported.';
        Text002: Label '%1 Records have been created.';
        Text003: Label 'The system has found the following aged clearing numbers:';
        Text004: Label 'The system successfully updated the following clearing numbers:';
        Text005: Label 'Clearingnumber %1 not found in %2.';
        Text006: Label 'The system has not automatically adjusted the following data. This has to be done manually.';
        Text007: Label 'The Entry %1 %2 cannot be updated.';
        Text008: Label 'All Files (*.*)|*.*';
        Text009: Label 'Open Bank Directory file';
        Text19057439: Label 'The latest Bank Directory file can be downloaded from www.sic.ch.';
        PageCaptionLbl: Label 'Page';
        ImportBankDirectoryCaptionLbl: Label 'Import Bank Directory';
        OldBankBranchNoCaptionLbl: Label 'Old Bank Branch No.';
        NewBankBranchNoCaptionLbl: Label 'New Bank Branch No.';
        OldCodeCaptionLbl: Label 'Old Code';
        OldClearingNoCaptionLbl: Label 'Old Clearing No.';
        NewClearingNoCaptionLbl: Label 'New Clearing No.';
        NewCodeCaptionLbl: Label 'New Code';
        OtherCaptionLbl: Label 'Other';
        TableCaptionLbl: Label 'Table';
        FieldCaptionLbl: Label 'Field';
        EntryCaptionLbl: Label 'Entry';

    [IntegrationEvent(false, false)]
    local procedure OnImportFile(var TempBlob: Codeunit "Temp Blob"; var FileName: Text; var IsHandled: Boolean)
    begin
    end;
}

