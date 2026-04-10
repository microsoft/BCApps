namespace System.IO;

using System.Reflection;

report 8614 "Get Config. Tables"
{
    Caption = 'Get Config. Tables';
    ProcessingOnly = true;

    dataset
    {
        dataitem(AllObj; AllObj)
        {
            DataItemTableView = where("Object Type" = const(Table), "Object ID" = filter(.. 99000999 | 2000000004 | 2000000005));
            RequestFilterFields = "Object ID", "Object Name";

            trigger OnPreDataItem()
            begin
                ConfigMgt.GetConfigTables(
                  AllObj, IncludeWithDataOnly, IncludeRelatedTables, IncludeDimensionTables, IncludeLicensedTablesOnly, true);
                CurrReport.Break();
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
                    field(IncludeWithDataOnly; IncludeWithDataOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include With Data Only';
                        ToolTip = 'Specifies if you want to include only those tables that have data.';
                    }
                    field(IncludeRelatedTables; IncludeRelatedTables)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Related Tables';
                        ToolTip = 'Specifies if you want to include related tables in your configuration package.';
                    }
                    field(IncludeDimensionTables; IncludeDimensionTables)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Include Dimension Tables';
                        ToolTip = 'Specifies whether to include dimension tables in the list of tables.';
                    }
                    field(IncludeLicensedTablesOnly; IncludeLicensedTablesOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Licensed Tables Only';
                        ToolTip = 'Specifies if you want to include only those tables for which the license under which you are creating the worksheet allows you access.';
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
        ConfigMgt: Codeunit "Config. Management";
        IncludeRelatedTables: Boolean;
        IncludeDimensionTables: Boolean;
        IncludeWithDataOnly: Boolean;
        IncludeLicensedTablesOnly: Boolean;

    procedure InitializeRequest(NewIncludeWithDataOnly: Boolean; NewIncludeRelatedTables: Boolean; NewIncludeDimensionTables: Boolean; NewIncludeLicensedTablesOnly: Boolean)
    begin
        IncludeWithDataOnly := NewIncludeWithDataOnly;
        IncludeRelatedTables := NewIncludeRelatedTables;
        IncludeDimensionTables := NewIncludeDimensionTables;
        IncludeLicensedTablesOnly := NewIncludeLicensedTablesOnly;
    end;
}

