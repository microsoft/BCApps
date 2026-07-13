#pragma warning disable AA0247
report 17450 "Spreadsheet Gen. Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/SpreadsheetGenJournal.rdlc';
    Caption = 'Spreadsheet Gen. Journal';

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Business Unit Code", "Shortcut Dimension 1 Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Gen__Journal_Line__Account_Type_; "Account Type")
            {
            }
            column(Gen__Journal_Line__Account_No__; "Account No.")
            {
            }
            column(Gen__Journal_Line__Posting_Date_; "Posting Date")
            {
            }
            column(Gen__Journal_Line__Document_Type_; "Document Type")
            {
            }
            column(Gen__Journal_Line__Document_No__; "Document No.")
            {
            }
            column(Gen__Journal_Line_Description; Description)
            {
            }
            column(Gen__Journal_Line__Bal__Account_No__; "Bal. Account No.")
            {
            }
            column(Gen__Journal_Line__Currency_Code_; "Currency Code")
            {
            }
            column(Gen__Journal_Line_Amount; Amount)
            {
            }
            column(Gen__Journal_Line__Debit_Amount_; "Debit Amount")
            {
            }
            column(Gen__Journal_Line__Credit_Amount_; "Credit Amount")
            {
            }
            column(Gen__Journal_Line__Shortcut_Dimension_1_Code_; "Shortcut Dimension 1 Code")
            {
            }
            column(Gen__Journal_Line__Business_Unit_Code_; "Business Unit Code")
            {
            }
            column(Gen__Journal_LineCaption; Gen__Journal_LineCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Gen__Journal_Line__Account_Type_Caption; FieldCaption("Account Type"))
            {
            }
            column(Gen__Journal_Line__Account_No__Caption; FieldCaption("Account No."))
            {
            }
            column(Gen__Journal_Line__Posting_Date_Caption; FieldCaption("Posting Date"))
            {
            }
            column(Gen__Journal_Line__Document_Type_Caption; FieldCaption("Document Type"))
            {
            }
            column(Gen__Journal_Line__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(Gen__Journal_Line_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Gen__Journal_Line__Bal__Account_No__Caption; FieldCaption("Bal. Account No."))
            {
            }
            column(Gen__Journal_Line__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(Gen__Journal_Line_AmountCaption; FieldCaption(Amount))
            {
            }
            column(Gen__Journal_Line__Debit_Amount_Caption; FieldCaption("Debit Amount"))
            {
            }
            column(Gen__Journal_Line__Credit_Amount_Caption; FieldCaption("Credit Amount"))
            {
            }
            column(Gen__Journal_Line__Shortcut_Dimension_1_Code_Caption; FieldCaption("Shortcut Dimension 1 Code"))
            {
            }
            column(Gen__Journal_Line__Business_Unit_Code_Caption; FieldCaption("Business Unit Code"))
            {
            }
            column(Gen__Journal_Line_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Gen__Journal_Line_Journal_Batch_Name; "Journal Batch Name")
            {
            }
            column(Gen__Journal_Line_Line_No_; "Line No.")
            {
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Gen__Journal_LineCaptionLbl: Label 'Gen. Journal Line';
        CurrReport_PAGENOCaptionLbl: Label 'PageNo';
}

