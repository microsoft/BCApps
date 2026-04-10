namespace System.IO;

using System.Reflection;

page 8624 "Config. Package Fields"
{
    Caption = 'Config. Package Fields';
    DataCaptionExpression = FormCaption();
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Config. Package Field";
    SourceTableView = sorting("Package Code", "Table ID", "Processing Order");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID for the table that is part of the migration process.';
                    Visible = false;
                }
                field(Dimension; Rec.Dimension)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies whether the field in the table is part of the dimension definition set.';
                }
                field("Field ID"; Rec."Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the field for the table that is part of the migration process.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the field for the table that is part of the migration process. The name comes from the Name property for the field.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the caption of the field for the table that is part of the migration process. The caption comes from the Caption property for the field.';
                    Visible = false;
                }
                field("Include Field"; Rec."Include Field")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IncludedEditable;
                    ToolTip = 'Specifies whether the field is included in the migration. Select the check box to include the field in the migration process. By default, when you select the check box, the Field Caption check box is also selected. You can clear this check box if you do not want to enable validation for the field.';
                }
                field("Validate Field"; Rec."Validate Field")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the information in a field is to be validated during migration. Select the check box if you want to enable validation for the field. This is useful when you want to limit data to a prescribed set of options.';
                }
                field("Processing Order"; Rec."Processing Order")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the order in which the data from the fields in the package should be applied. If your business logic requires that a certain field be filled in before another field can contain data, you can use the Processing Order field to specify the appropriate order. To specify the order, use the Move Up and Move Down commands on the Actions tab in the Config. Package Fields window. When you export the configuration information to Excel, the order that you specify for processing is the order in which the fields will be listed in columns in Excel.';
                }
                field("Primary Key"; Rec."Primary Key")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the field is part of the definition of the primary key for the table.';
                    Visible = false;
                }
                field(AutoIncrement; Rec.AutoIncrement)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the field has the AutoIncrement property set to Yes, but is not part of the definition of the primary key for the table.';
                    Visible = false;
                }
                field("Localize Field"; Rec."Localize Field")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies whether the field is to be localized.';
                    Visible = false;
                }
                field("Relation Table ID"; Rec."Relation Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the ID for the table that contains a field that is related to the one in the migration table. For example, the Post Code table has a relationship with the City field in the Company Information migration table.';
                }
                field("Relation Table Caption"; Rec."Relation Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the table with a relationship to the migration field.';
                }
                field("Create Missing Codes"; Rec."Create Missing Codes")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether you can create additional values in the database during the configuration migration process. Select the check box to indicate that additional codes can be added to that field in Business Central during the import of data from Excel.';
                }
                field("Mapping Exists"; Rec."Mapping Exists")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the field has a mapping assigned to it that is to be used during data migration.';

                    trigger OnDrillDown()
                    var
                        ConfigPackageManagement: Codeunit "Config. Package Management";
                    begin
                        ConfigPackageManagement.ShowFieldMapping(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Fiel&ds")
            {
                Caption = 'Fiel&ds';
                action("Set Included")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Included';
                    Image = Completed;
                    ToolTip = 'Specify that the field is included in the package.';

                    trigger OnAction()
                    var
                        ConfigPackageField: Record "Config. Package Field";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                    begin
                        ConfigPackageField.CopyFilters(Rec);
                        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, true);
                    end;
                }
                action("Clear Included")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear Included';
                    Image = ResetStatus;
                    ToolTip = 'Deselect the included fields. To include all fields, choose the Set Included action.';

                    trigger OnAction()
                    var
                        ConfigPackageField: Record "Config. Package Field";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                    begin
                        ConfigPackageField.CopyFilters(Rec);
                        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, false);
                    end;
                }
                action(Mapping)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mapping';
                    Ellipsis = true;
                    Image = MapAccounts;
                    ToolTip = 'View the mapping of values from an existing ERP system into the Business Central implementation during the migration of data.';

                    trigger OnAction()
                    var
                        ConfigPackageManagement: Codeunit "Config. Package Management";
                    begin
                        ConfigPackageManagement.ShowFieldMapping(Rec);
                    end;
                }
                action("Move Up")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Up';
                    Image = MoveUp;
                    ToolTip = 'Move the selected line up in the list.';

                    trigger OnAction()
                    var
                        ConfigPackageField: Record "Config. Package Field";
                    begin
                        CurrPage.SaveRecord();
                        ConfigPackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");
                        ConfigPackageField.SetRange("Package Code", Rec."Package Code");
                        ConfigPackageField.SetRange("Table ID", Rec."Table ID");
                        ConfigPackageField.SetFilter("Processing Order", '..%1', Rec."Processing Order" - 1);
                        if ConfigPackageField.FindLast() then begin
                            ExchangeLines(Rec, ConfigPackageField);
                            CurrPage.Update(false);
                        end;
                    end;
                }
                action("Move Down")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Down';
                    Image = MoveDown;
                    ToolTip = 'Move the selected line down in the list.';

                    trigger OnAction()
                    var
                        ConfigPackageField: Record "Config. Package Field";
                    begin
                        CurrPage.SaveRecord();
                        ConfigPackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");
                        ConfigPackageField.SetRange("Package Code", Rec."Package Code");
                        ConfigPackageField.SetRange("Table ID", Rec."Table ID");
                        ConfigPackageField.SetFilter("Processing Order", '%1..', Rec."Processing Order" + 1);
                        if ConfigPackageField.FindFirst() then begin
                            ExchangeLines(Rec, ConfigPackageField);
                            CurrPage.Update(false);
                        end;
                    end;
                }
                action("Change Related Table")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Related Table';
                    Enabled = ChangeTableRelationEnabled;
                    Image = Splitlines;
                    ToolTip = 'Change a related table of Config. Package Field if the related field has 2 or more related tables.';

                    trigger OnAction()
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                        Objects: Page Objects;
                    begin
                        Clear(Objects);
                        AllObjWithCaption.FilterGroup(2);
                        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                        AllObjWithCaption.SetFilter("Object ID", Rec.GetRelationTablesID());
                        AllObjWithCaption.FilterGroup(0);
                        Objects.SetTableView(AllObjWithCaption);
                        Objects.LookupMode := true;
                        if Objects.RunModal() = ACTION::LookupOK then begin
                            Objects.GetRecord(AllObjWithCaption);
                            Rec.Validate("Relation Table ID", AllObjWithCaption."Object ID");
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Move Up_Promoted"; "Move Up")
                {
                }
                actionref("Move Down_Promoted"; "Move Down")
                {
                }
                actionref("Set Included_Promoted"; "Set Included")
                {
                }
                actionref("Clear Included_Promoted"; "Clear Included")
                {
                }
                actionref(Mapping_Promoted; Mapping)
                {
                }
                actionref("Change Related Table_Promoted"; "Change Related Table")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        ChangeTableRelationEnabled := ConfigPackageManagement.IsFieldMultiRelation(Rec."Table ID", Rec."Field ID");
        if ChangeTableRelationEnabled and not CurrPage.Editable then
            ChangeTableRelationEnabled := CurrPage.Editable;
    end;

    trigger OnAfterGetRecord()
    begin
        IncludedEditable := not Rec."Primary Key";
    end;

    var
        IncludedEditable: Boolean;
        ChangeTableRelationEnabled: Boolean;

    local procedure FormCaption(): Text[1024]
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        if ConfigPackageTable.Get(Rec."Package Code", Rec."Table ID") then
            ConfigPackageTable.CalcFields("Table Caption");

        exit(ConfigPackageTable."Table Caption");
    end;

    protected procedure ExchangeLines(var ConfigPackageField1: Record "Config. Package Field"; var ConfigPackageField2: Record "Config. Package Field")
    var
        ProcessingOrder: Integer;
    begin
        if ConfigPackageField1."Primary Key" <> ConfigPackageField2."Primary Key" then
            exit;

        ProcessingOrder := ConfigPackageField1."Processing Order";
        ConfigPackageField1."Processing Order" := ConfigPackageField2."Processing Order";
        ConfigPackageField2."Processing Order" := ProcessingOrder;
        ConfigPackageField1.Modify();
        ConfigPackageField2.Modify();
    end;
}
