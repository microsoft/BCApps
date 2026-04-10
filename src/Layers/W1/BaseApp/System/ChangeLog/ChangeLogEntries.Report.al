namespace System.Diagnostics;

report 509 "Change Log Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './System/ChangeLog/ChangeLogEntries.rdlc';
    Caption = 'Change Log Entries';

    dataset
    {
        dataitem("Change Log Entry"; "Change Log Entry")
        {
            RequestFilterFields = "Date and Time";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Change_Log_Entry__GETFILTERS; GetFilters)
            {
            }
            column(Change_Log_Entry__Table_Name_; "Table Caption")
            {
            }
            column(Change_Log_Entry__Primary_Key_; "Primary Key")
            {
            }
            column(Change_Log_Entry__Field_Name_; "Field Caption")
            {
            }
            column(Change_Log_Entry__Type_of_Change_; "Type of Change")
            {
            }
            column(Change_Log_Entry__Old_Value_; GetLocalOldValue())
            {
            }
            column(Change_Log_Entry__New_Value_; GetLocalNewValue())
            {
            }
            column(Change_Log_Entry__User_ID_; "User ID")
            {
            }
            column(DT2DATE__Date_and_Time__; Format(DT2Date("Date and Time")))
            {
            }
            column(Change_Log_Entry_Time; Time)
            {
            }
            column(Change_Log_Entry_Date_and_Time; "Date and Time")
            {
            }
            column(Change_Log_EntriesCaption; Change_Log_EntriesCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(FiltersCaption; FiltersCaptionLbl)
            {
            }
            column(Change_Log_Entry__Table_Name_Caption; FieldCaption("Table Caption"))
            {
            }
            column(Change_Log_Entry__Primary_Key_Caption; FieldCaption("Primary Key"))
            {
            }
            column(Change_Log_Entry__Field_Name_Caption; FieldCaption("Field Caption"))
            {
            }
            column(Change_Log_Entry__Type_of_Change_Caption; FieldCaption("Type of Change"))
            {
            }
            column(Change_Log_Entry__Old_Value_Caption; FieldCaption("Old Value"))
            {
            }
            column(Change_Log_Entry__New_Value_Caption; FieldCaption("New Value"))
            {
            }
            column(Change_Log_Entry__User_ID_Caption; FieldCaption("User ID"))
            {
            }
            column(DT2DATE__Date_and_Time__Caption; DT2DATE__Date_and_Time__CaptionLbl)
            {
            }
            column(Change_Log_Entry_TimeCaption; FieldCaption(Time))
            {
            }
            column(PrimaryKey; PrimaryKey)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Table Caption", "Field Caption");
                PrimaryKey := GetFullPrimaryKeyFriendlyName();
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
        Change_Log_EntriesCaptionLbl: Label 'Change Log Entries';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        FiltersCaptionLbl: Label 'Filters';
        DT2DATE__Date_and_Time__CaptionLbl: Label 'Date';
        PrimaryKey: Text;
}

