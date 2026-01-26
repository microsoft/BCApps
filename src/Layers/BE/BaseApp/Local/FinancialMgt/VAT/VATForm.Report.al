// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Company;
using System;
using System.IO;
using System.Telemetry;
using System.Utilities;
using System.Xml;

report 11307 "VAT - Form"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Form/Intervat Declaration';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name") where("Print on Official VAT Form" = const(true));

                trigger OnAfterGetRecord()
                var
                    VATStatement: Report "VAT Statement";
                    PeriodSelection: Enum "VAT Statement Report Period Selection";
                    CorrectionAmount: Decimal;
                    Dummy: Decimal;
                begin
                    Clear(TotalAmount);
                    SetRange("Date Filter", Vdatefrom, Vdateto);
                    VATStatement.InitializeRequest(
                      "VAT Statement Name", "VAT Statement Line", IncludeVatEntries,
                      PeriodSelection::"Within Period", false, false);
                    VATStatement.CalcLineTotal("VAT Statement Line", TotalAmount, CorrectionAmount, Dummy, '', 0);
                    TotalAmount := TotalAmount + CorrectionAmount;
                    if "Print with" = "Print with"::"Opposite Sign" then
                        TotalAmount := -TotalAmount;

                    Clear(No);
                    if (TotalAmount <> 0) and ("Row No." <> '') then
                        if Evaluate(No, "Row No.") then begin
                            if No in [1 .. 99] then begin
                                if (No <> 91) or
                                   ((No = 91) and (PrintPrepayment = PrintPrepayment::Amount))
                                then
                                    AssignRow(No, TotalAmount)
                            end else
                                if "Row No." = '00' then
                                    AssignRow(0, TotalAmount);
                        end else
                            if "Row No." = '71/72' then
                                if TotalAmount < 0 then
                                    AssignRow(71, Abs(TotalAmount))
                                else
                                    AssignRow(72, TotalAmount);
                end;
            }
            dataitem("Generate INTERVAT File"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                var
                    RunResults: Boolean;
                begin
                    RunResults := CreateInterVatXml();

                    if SilenceRun then
                        exit;

                    if not RunResults then
                        Message(Text012);
                end;
            }

            trigger OnPreDataItem()
            begin
                SetRange("Statement Template Name", GLSetup."VAT Statement Template Name");
                SetRange(Name, GLSetup."VAT Statement Name");
                ValidatePeriod();
                if AddRepresentative then begin
                    Representative.Get(Identifier);
                    Representative.CheckCompletion();
                end;
            end;
        }
    }

    requestpage
    {
        DeleteAllowed = false;
        InsertAllowed = false;
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Control1010021)
                    {
                        ShowCaption = false;
                        group(Period)
                        {
                            Caption = 'Period';
                            field(ChoicePeriodType; ChoicePeriodType)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Declaration Type';
                                OptionCaption = 'Month,Quarter';
                                ToolTip = 'Specifies the type of declaration that you want to print. Options include Month and Quarter.';

                                trigger OnValidate()
                                begin
                                    if ChoicePeriodType = ChoicePeriodType::Quarter then
                                        QuarterChoicePeriodTypeOnValid();
                                    if ChoicePeriodType = ChoicePeriodType::Month then
                                        MonthChoicePeriodTypeOnValidat();
                                end;
                            }
                            field(Vperiod; Vperiod)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Month or Quarter';
                                ToolTip = 'Specifies the month or quarter of the VAT declaration. If you select Month in the Declaration Type field, you must enter a value between 1 and 12 (1 = January, 2 = February, 3 = March, and so on). If you select Quarter, you must enter a value between 1 and 4 (1 = first quarter, 2 = second quarter, 3= third quarter, 4 = fourth quarter).';

                                trigger OnValidate()
                                begin
                                    ValidatePeriod();
                                end;
                            }
                            field(Vyear; Vyear)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Year (YYYY)';
                                ToolTip = 'Specifies the year of the VAT declaration. You should enter the year as a four digit code. For example, to print a declaration for 2013, you should enter "2013" (instead of "13").';

                                trigger OnValidate()
                                begin
                                    FeatureTelemetry.LogUptake('1000HL1', BEVATTok, Enum::"Feature Uptake Status"::"Set up");
                                    if not (Vyear in [1997 .. 2050]) then
                                        Error(Text005);
                                end;
                            }
                            field(IncludeVatEntries; IncludeVatEntries)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Include VAT Entries';
                                ToolTip = 'Specifies the VAT entries to be included in the report. You can choose between Open, Closed and Open and Closed.';
                            }
                        }
                        group(Prepayment)
                        {
                            Caption = 'Prepayment';
                            field(PrintPrepayment; PrintPrepayment)
                            {
                                ApplicationArea = Prepayments;
                                OptionCaption = 'Print Prepmt. Amount,Print Zero (No Prepayment),Leave Empty (Use November Amount)';
                                ToolTip = 'Specifies how prepayments should be handled in the VAT declaration (case 91). Options include Print Prepmt. Amount, Print Zero (No Prepayment), and Leave Empty (User November Amount). Note that case 91 must not be filled for quarterly VAT declarations or for declarations in months other than December.';
                            }
                        }
                        group(Other)
                        {
                            Caption = 'Other';
                            field(Reimbursement; Reimbursement)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Claim for Reimbursement';
                                ToolTip = 'Specifies if you want to claim the reimbursement of the amount due by the tax authorities after you have submitted the declaration.';
                            }
                            field(PaymForms; PaymForms)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Order Payment Forms';
                                ToolTip = 'Specifies if you want to order new payment forms.';
                            }
                            field(Annuallist; Annuallist)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'No Annual Listing';
                                ToolTip = 'Specifies if you do not want an annual listing for the declaration. You can only select this option for the last declaration of the calendar year.';
                            }
                            field(IsCorrectionControl; IsCorrection)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Correction';
                                ToolTip = 'Specifies that the entry is a corrective entry.';

                                trigger OnValidate()
                                begin
                                    PrevSequenceNo := 0;
                                end;
                            }
                            field(PrevSequenceNoControl; PrevSequenceNo)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Previous Sequence No.';
                                Enabled = IsCorrection;
                                ToolTip = 'Specifies the sequence number of the previously submitted declaration.';
                            }
                            field(CommentControl; Comment)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Comment';
                                ToolTip = 'Specifies the comment for the declaration.';
                            }
                        }
                    }
                    group("&Representative")
                    {
                        Caption = '&Representative';
                        field(AddRepresentative; AddRepresentative)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Add Representative';
                            ToolTip = 'Specifies if you want to add a VAT declaration representative. A representative is a person or an agency that has license to make a VAT declaration.';

                            trigger OnValidate()
                            begin
                                SetRepresentativeEnabled();
                            end;
                        }
                        field(ID; Identifier)
                        {
                            ApplicationArea = Basic, Suite;
                            Enabled = IDEnable;
                            TableRelation = Representative;
                            ToolTip = 'Specifies the ID of the representative who is responsible for making the VAT declaration.';
                        }
                    }
                    label(Control1010023)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19039936;
                        ShowCaption = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            IDEnable := true;
            PrintPrepayment := PrintPrepayment::Empty;
        end;

        trigger OnOpenPage()
        begin
            SetRepresentativeEnabled();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        CompanyInformation: Record "Company Information";
        CheckVatNo: Codeunit VATLogicalTests;
    begin
        FeatureTelemetry.LogUptake('1000HL0', BEVATTok, Enum::"Feature Uptake Status"::Discovered);
        CompanyInformation.Get();
        if not CheckVatNo.MOD97Check(CompanyInformation."Enterprise No.") then
            Error(Text001, CompanyInformation.FieldCaption("Enterprise No."), CompanyInformation.TableCaption());
        CompanyInformation.TestField("Country/Region Code");

        GLSetup.Get();
        GLSetup.TestField("VAT Statement Template Name");
        GLSetup.TestField("VAT Statement Name");
    end;

    trigger OnPreReport()
    begin
        if not AddRepresentative then
            INTERVATHelper.VerifyCpyInfoEmailExists();

        if Vperiod = 0 then
            Error(Text015);
        if Vyear = 0 then
            Error(Text016);

        if ChoicePeriodType = ChoicePeriodType::Quarter then begin
            Vdatefrom := DMY2Date(1, (Vperiod - 1) * 3 + 1, Vyear);
            Vdateto := CalcDate('<+CQ>', Vdatefrom);
        end else begin
            Vdatefrom := DMY2Date(1, Vperiod, Vyear);
            Vdateto := CalcDate('<+CM>', Vdatefrom);
        end;

        if (Vperiod <> 12) and (PrintPrepayment <> PrintPrepayment::Empty) then
            Error(Text013);

        Clear(Row);
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('1000HL2', BEVATTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('1000HL3', BEVATTok, 'BE Periodic VAT Report Printed');
    end;

    var
        Text001: Label '%1 in table %2 is not valid.';
        Text005: Label 'Year must be between 1997 and 2050.';
        Text006: Label 'Quarter must be between 1 and 4.';
        Text007: Label 'Month must be between 1 and 12.';
        Text012: Label 'Problem creating INTERVAT XML File.';
        Text013: Label 'Row [91] should only be filled in for transactions in the month of December.';
        BEVATTok: Label 'BE Periodic VAT Statement', Locked = true;
        GLSetup: Record "General Ledger Setup";
        Representative: Record Representative;
        INTERVATHelper: Codeunit "INTERVAT Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IncludeVatEntries: Enum "VAT Statement Report Selection";
        IsCorrection: Boolean;
        ChoicePeriodType: Option Month,Quarter;
        PrevSequenceNo: Integer;
        PrintPrepayment: Option Amount,Zero,Empty;
        DocNameSpace: Text[50];
        FileName: Text;
        Reimbursement: Boolean;
        PaymForms: Boolean;
        RefreshSequenceNumber: Boolean;
        Vperiod: Integer;
        Vyear: Integer;
        TotalAmount: Decimal;
        No: Decimal;
        Row: array[99] of Decimal;
        Vdatefrom: Date;
        Vdateto: Date;
        Text015: Label 'Month or quarter must not be Zero.';
        Text016: Label 'Year (YYYY) must not be Zero.';
        Annuallist: Boolean;
        SilenceRun: Boolean;
        AddRepresentative: Boolean;
        IDEnable: Boolean;
        Text19039936: Label 'The report generates a XML file according to the INTERVAT 8.0 schema defined by the Belgium tax authority.';
        Identifier: Text[20];
        ClientFileNameTxt: Label 'Intervat.xml', Locked = true;
        Comment: Text;

    local procedure AssignRow(j: Integer; Amount: Decimal)
    begin
        if j <= 0 then
            j := 99;

        Row[j] := Amount;
    end;

    local procedure GetSequenceNumber(): Integer
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if RefreshSequenceNumber then begin
            CompanyInformation."XML Seq. No. VAT Declaration" := CompanyInformation."XML Seq. No. VAT Declaration" + 1;
            if CompanyInformation."XML Seq. No. VAT Declaration" > 9999 then
                CompanyInformation."XML Seq. No. VAT Declaration" := 1;
            CompanyInformation.Modify();
            RefreshSequenceNumber := false;
        end;

        exit(CompanyInformation."XML Seq. No. VAT Declaration");
    end;

    local procedure CreateInterVatXml() ReturnValue: Boolean
    var
        FileManagement: Codeunit "File Management";
        XMLDocOut: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLFirstNode: DotNet XmlNode;
        ServerFileName: Text;
    begin
        ReturnValue := false;
        RefreshSequenceNumber := true;

        XMLDOMMgt.LoadXMLDocumentFromText('<VATConsignment/>', XMLDocOut);

        XMLCurrNode := XMLDocOut.DocumentElement;
        XMLFirstNode := XMLCurrNode;

        INTERVATHelper.AddProcessingInstruction(XMLDocOut, XMLFirstNode);
        AddHeader(XMLCurrNode);
        XMLFirstNode := XMLCurrNode;

        if AddRepresentative then begin
            Representative.AddRepresentativeElement(XMLCurrNode, DocNameSpace, GetSequenceNumber());
            XMLCurrNode := XMLFirstNode;
        end;

        AddElementVatDeclaration(XMLCurrNode);
        XMLFirstNode := XMLCurrNode;

        if IsCorrection then
            AddElementReplacedVATDeclaration(XMLCurrNode);

        INTERVATHelper.AddElementDeclarant(XMLCurrNode, GetSequenceNumber(), '');
        XMLCurrNode := XMLFirstNode;

        INTERVATHelper.AddElementPeriod(XMLCurrNode, ChoicePeriodType, Vperiod, Vyear, '');
        XMLCurrNode := XMLFirstNode;

        AddElementData(XMLCurrNode);
        XMLCurrNode := XMLFirstNode;

        AddElementClientListingNihil(XMLFirstNode);
        AddElementAsk(XMLFirstNode);

        AddElementComment(XMLFirstNode);
        XMLCurrNode := XMLFirstNode;

        ServerFileName := FileManagement.ServerTempFileName('.xml');
        XMLDocOut.Save(ServerFileName);
        if FileName = '' then
            FileManagement.DownloadHandler(ServerFileName, '', '', FileManagement.GetToFilterText('', ServerFileName), ClientFileNameTxt)
        else
            FileManagement.CopyServerFile(ServerFileName, FileName, true);
        FileManagement.DeleteServerFile(ServerFileName);

        ReturnValue := true;
    end;

    local procedure CreateDataElement(XMLCurrNode: DotNet XmlNode; Amount: Decimal; ExternalRowNo: Integer)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(
          XMLCurrNode, 'Amount', INTERVATHelper.GetXMLAmountRepresentation(Amount), DocNameSpace, XMLNewChild);

        XMLDOMMgt.AddAttribute(XMLNewChild, 'GridNumber', Format(ExternalRowNo));
    end;

    local procedure AddElementAsk(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'Ask', '', DocNameSpace, XMLNewChild);
        XMLDOMMgt.AddAttribute(XMLNewChild, 'Restitution', YesNo(Reimbursement));
        XMLDOMMgt.AddAttribute(XMLNewChild, 'Payment', YesNo(PaymForms));
    end;

    local procedure AddElementComment(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'Comment', Comment, DocNameSpace, XMLNewChild);
    end;

    local procedure AddElementClientListingNihil(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'ClientListingNihil', YesNo(Annuallist), DocNameSpace, XMLNewChild);
    end;

    local procedure AddElementData(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
        i: Integer;
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'Data', '', DocNameSpace, XMLNewChild);

        XMLCurrNode := XMLNewChild;
        // case 0, internally saved as 99
        if Row[99] > 0 then
            CreateDataElement(XMLCurrNode, Row[99], 0);

        // other cases
        for i := 1 to 98 do
            if i <> 91 then begin
                if Row[i] > 0 then
                    CreateDataElement(XMLCurrNode, Row[i], i);
                if (i = 72) and (Row[71] = 0) and (Row[72] = 0) then
                    CreateDataElement(XMLCurrNode, 0.0, 71);
            end else // case 91 not mentioned (must be blank)
                case PrintPrepayment of
                    PrintPrepayment::Amount:
                        CreateDataElement(XMLCurrNode, Row[91], i);
                    PrintPrepayment::Zero:
                        CreateDataElement(XMLCurrNode, Row[91], i);
                end;
    end;

    local procedure AddElementReplacedVATDeclaration(var XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(
          XMLCurrNode, 'ReplacedVATDeclaration', INTERVATHelper.GetReplacedVATDeclaration(PrevSequenceNo, VPeriod, VYear), DocNameSpace, XMLNewChild);
    end;

    local procedure AddElementVatDeclaration(var XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'VATDeclaration', '', DocNameSpace, XMLNewChild);

        XMLCurrNode := XMLNewChild;
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'SequenceNumber', '1');
    end;

    local procedure AddHeader(XMLCurrNode: DotNet XmlNode)
    begin
        DocNameSpace := 'http://www.minfin.fgov.be/VATConsignment';
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'VATDeclarationsNbr', '1');
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns', DocNameSpace);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns:common', 'http://www.minfin.fgov.be/InputCommon');
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');

        XMLDOMMgt.AddNameSpacePrefixedAttribute(
          XMLCurrNode.OwnerDocument, XMLCurrNode,
          'http://www.w3.org/2001/XMLSchema-instance',
          'schemaLocation',
          DocNameSpace + ' NewTVA-in_v0_9.xsd');
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewChoicePeriodType: Integer; NewVPeriod: Integer; NewVyear: Integer; NewIncludeVatEntries: Integer; NewPrintPrepayment: Integer; NewReimbursement: Boolean; NewPaymForms: Boolean; NewAnnuallist: Boolean; NewFileName: Text[1024])
    begin
        ChoicePeriodType := NewChoicePeriodType;
        Vperiod := NewVPeriod;
        Vyear := NewVyear;
        IncludeVatEntries := "VAt Statement Report Selection".FromInteger(NewIncludeVatEntries);
        PrintPrepayment := NewPrintPrepayment;
        Reimbursement := NewReimbursement;
        PaymForms := NewPaymForms;
        Annuallist := NewAnnuallist;
        FileName := NewFileName;
        SilenceRun := true;
    end;

    [Scope('OnPrem')]
    procedure SetFileName(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure InitializeRepresentative(NewAddRepresentative: Boolean)
    begin
        AddRepresentative := NewAddRepresentative;
    end;

    local procedure ValidatePeriod()
    begin
        if ChoicePeriodType = ChoicePeriodType::Quarter then begin
            if not (Vperiod in [1 .. 4]) then
                Error(Text006);
        end else
            if not (Vperiod in [1 .. 12]) then
                Error(Text007);
    end;

    local procedure SetRepresentativeEnabled()
    begin
        PageSetRepresentativeEnabled();
    end;

    local procedure YesNo(Boolean: Boolean): Text[3]
    begin
        if Boolean then
            exit('YES');
        exit('NO');
    end;

    local procedure PageSetRepresentativeEnabled()
    begin
        IDEnable := AddRepresentative;
    end;

    local procedure MonthChoicePeriodTypeOnValidat()
    begin
        ValidatePeriod();
    end;

    local procedure QuarterChoicePeriodTypeOnValid()
    begin
        ValidatePeriod();
    end;
}

