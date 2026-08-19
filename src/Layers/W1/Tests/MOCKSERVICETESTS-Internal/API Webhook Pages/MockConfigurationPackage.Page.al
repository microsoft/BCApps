page 135185 "Mock - Configuration Package"
{
    APIGroup = 'webhook';
    APIPublisher = 'mock';
    APIVersion = 'v0.1';
    Caption = 'configurationPackage', Locked = true;
    DelayedInsert = true;
    EntityName = 'configurationPackage';
    EntitySetName = 'configurationPackages';
    PageType = API;
    SourceTable = "Config. Package";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;
                }
                field(packageName; "Package Name")
                {
                    ApplicationArea = All;
                    Caption = 'PackageName', Locked = true;
                    ToolTip = 'Specifies the name of the package.';
                }
                field(languageId; "Language ID")
                {
                    ApplicationArea = All;
                    Caption = 'LanguageId', Locked = true;
                }
                field(productVersion; "Product Version")
                {
                    ApplicationArea = All;
                    Caption = 'ProductVersion', Locked = true;
                }
                field(processingOrder; "Processing Order")
                {
                    ApplicationArea = All;
                    Caption = 'ProcessingOrder', Locked = true;
                }
                field(excludeConfigurationTables; "Exclude Config. Tables")
                {
                    ApplicationArea = All;
                    Caption = 'ExcludeConfigurationTables', Locked = true;
                }
                field(numberOfTables; "No. of Tables")
                {
                    ApplicationArea = All;
                    Caption = 'NumberOfTables', Locked = true;
                    Editable = false;
                }
                field(numberOfRecords; "No. of Records")
                {
                    ApplicationArea = All;
                    Caption = 'NumberOfRecords', Locked = true;
                    Editable = false;
                }
                field(numberOfErrors; "No. of Errors")
                {
                    ApplicationArea = All;
                    Caption = 'NumberOfErrors', Locked = true;
                    Editable = false;
                }
                field(importStatus; "Import Status")
                {
                    ApplicationArea = All;
                    Caption = 'ImportStatus', Locked = true;
                    Editable = false;
                }
                field(applyStatus; "Apply Status")
                {
                    ApplicationArea = All;
                    Caption = 'ApplyStatus', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }
}
