namespace System.Diagnostics;

report 508 "Change Log Setup List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './System/ChangeLog/ChangeLogSetupList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Change Log Setup List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Change Log Setup (Table)"; "Change Log Setup (Table)")
        {
            DataItemTableView = sorting("Table No.");
            RequestFilterFields = "Table No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ChangeLogSetup__Change_Log_Activated_; Format(ChangeLogSetup."Change Log Activated"))
            {
            }
            column(Change_Log_Setup__Table___GETFILTERS; GetFilters)
            {
            }
            column(Change_Log_Setup__Table___Table_No__; "Table No.")
            {
            }
            column(Change_Log_Setup__Table___Table_Name_; "Table Caption")
            {
            }
            column(Change_Log_Setup__Table___Log_Insertion_; "Log Insertion")
            {
            }
            column(Change_Log_Setup__Table___Log_Modification_; "Log Modification")
            {
            }
            column(Change_Log_Setup__Table___Log_Deletion_; "Log Deletion")
            {
            }
            column(Change_Log_SetupCaption; Change_Log_SetupCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ChangeLogSetup__Change_Log_Activated_Caption; ChangeLogSetup__Change_Log_Activated_CaptionLbl)
            {
            }
            column(Change_Log_Setup__Table___GETFILTERSCaption; Change_Log_Setup__Table___GETFILTERSCaptionLbl)
            {
            }
            column(Change_Log_Setup__Table___Table_No__Caption; FieldCaption("Table No."))
            {
            }
            column(Change_Log_Setup__Table___Table_Name_Caption; FieldCaption("Table Caption"))
            {
            }
            column(Change_Log_Setup__Table___Log_Insertion_Caption; FieldCaption("Log Insertion"))
            {
            }
            column(Change_Log_Setup__Table___Log_Modification_Caption; FieldCaption("Log Modification"))
            {
            }
            column(Change_Log_Setup__Table___Log_Deletion_Caption; FieldCaption("Log Deletion"))
            {
            }
            dataitem("Change Log Setup (Field)"; "Change Log Setup (Field)")
            {
                DataItemLink = "Table No." = field("Table No.");
                DataItemTableView = sorting("Table No.", "Field No.");
                column(Number; Number)
                {
                }
                column(Change_Log_Setup__Field___Field_No__; "Field No.")
                {
                }
                column(Change_Log_Setup__Field___Field_Caption_; "Field Caption")
                {
                }
                column(Change_Log_Setup__Field___Log_Insertion_; Format("Log Insertion"))
                {
                }
                column(Change_Log_Setup__Field___Log_Modification_; Format("Log Modification"))
                {
                }
                column(Change_Log_Setup__Field___Log_Deletion_; Format("Log Deletion"))
                {
                }
                column(Change_Log_Setup__Field__Table_No_; "Table No.")
                {
                }
                column(Change_Log_Setup__Field___Field_No__Caption; FieldCaption("Field No."))
                {
                }
                column(Change_Log_Setup__Field___Field_Caption_Caption; FieldCaption("Field Caption"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Number := Number + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Number := 0;
            end;

            trigger OnPreDataItem()
            begin
                ChangeLogSetup.Get();
            end;
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
        ChangeLogSetup: Record "Change Log Setup";
        Number: Integer;
        Change_Log_SetupCaptionLbl: Label 'Change Log Setup';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ChangeLogSetup__Change_Log_Activated_CaptionLbl: Label 'Change Log Activated';
        Change_Log_Setup__Table___GETFILTERSCaptionLbl: Label 'Filters';
}

