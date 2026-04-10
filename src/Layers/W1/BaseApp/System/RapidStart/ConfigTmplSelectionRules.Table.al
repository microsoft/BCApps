namespace System.IO;

using System.Automation;
using System.Reflection;
using System.Utilities;

table 8620 "Config. Tmpl. Selection Rules"
{
    Caption = 'Config. Tmpl. Selection Rules';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(2; "Template Code"; Code[10])
        {
            Caption = 'Template Code';
            NotBlank = true;
            TableRelation = "Config. Template Header".Code where("Table ID" = field("Table ID"));
        }
        field(5; "Selection Criteria"; BLOB)
        {
            Caption = 'Selection Criteria';
        }
        field(6; Description; Text[250])
        {
            CalcFormula = lookup("Config. Template Header".Description where(Code = field("Template Code"),
                                                                              "Table ID" = field("Table ID")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Order"; Integer)
        {
            Caption = 'Order';
        }
        field(11; "Page ID"; Integer)
        {
            Caption = 'Page ID';

            trigger OnValidate()
            var
                PageMetadata: Record "Page Metadata";
            begin
                if "Table ID" > 0 then
                    exit;

                PageMetadata.Get("Page ID");
                Validate("Table ID", PageMetadata.SourceTable);
            end;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Template Code", "Page ID")
        {
            Clustered = true;
        }
        key(Key2; "Order")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DefineFiltersTxt: Label 'Specify criteria for when the template will be applied.';

    [Scope('OnPrem')]
    procedure SetSelectionCriteria()
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        CurrentFilters: Text;
        NewFilters: Text;
    begin
        TestField("Table ID");
        TestField("Template Code");

        CurrentFilters := GetExistingFilters();

        if not RequestPageParametersHelper.ShowRequestPageAndGetFilters(NewFilters, CurrentFilters, '', "Table ID", DefineFiltersTxt) then begin
            if not ConfigTmplSelectionRules.Get("Table ID", "Template Code", "Page ID") then
                Insert(true);
            exit;
        end;

        SaveTextFilter(NewFilters);

        if not ConfigTmplSelectionRules.Get("Table ID", "Template Code", "Page ID") then
            Insert(true)
        else
            Modify(true);
    end;

    local procedure GetExistingFilters() Filters: Text
    var
        FiltersInStream: InStream;
    begin
        CalcFields("Selection Criteria");
        if not "Selection Criteria".HasValue() then
            exit;

        "Selection Criteria".CreateInStream(FiltersInStream);
        FiltersInStream.Read(Filters);
    end;

    [Scope('OnPrem')]
    procedure GetFiltersAsTextDisplay(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FiltersRecordRef: RecordRef;
    begin
        FiltersRecordRef.Open("Table ID");
        CalcFields("Selection Criteria");
        TempBlob.FromRecord(Rec, FieldNo("Selection Criteria"));

        if RequestPageParametersHelper.ConvertParametersToFilters(FiltersRecordRef, TempBlob) then
            exit(FiltersRecordRef.GetFilters);

        exit('');
    end;

    local procedure SaveTextFilter(NewFilters: Text)
    var
        FiltersOutStream: OutStream;
    begin
        Clear("Selection Criteria");
        "Selection Criteria".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(NewFilters);
    end;

    procedure FindTemplateBasedOnRecordFields(RecordVariant: Variant; var ConfigTemplateHeader: Record "Config. Template Header"): Boolean
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        TempBlob: Codeunit "Temp Blob";
        DataTypeManagement: Codeunit "Data Type Management";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        RecRef: RecordRef;
        SearchRecRef: RecordRef;
        SearchRecRefVariant: Variant;
    begin
        if not DataTypeManagement.GetRecordRef(RecordVariant, RecRef) then
            exit(false);

        ConfigTmplSelectionRules.SetCurrentKey(Order);
        ConfigTmplSelectionRules.Ascending(true);
        ConfigTmplSelectionRules.SetRange("Table ID", RecRef.Number);
        ConfigTmplSelectionRules.SetAutoCalcFields("Selection Criteria");
        if not ConfigTmplSelectionRules.FindSet(false) then
            exit(false);

        // Insert RecRef on a temporary table
        SearchRecRef.Open(RecRef.Number, true);
        SearchRecRefVariant := SearchRecRef;
        RecRef.SetTable(SearchRecRefVariant);
        DataTypeManagement.GetRecordRef(SearchRecRefVariant, SearchRecRef);
        SearchRecRef.Insert();

        repeat
            TempBlob.FromRecord(ConfigTmplSelectionRules, ConfigTmplSelectionRules.FieldNo("Selection Criteria"));
            if not TempBlob.HasValue() then
                exit(ConfigTemplateHeader.Get(ConfigTmplSelectionRules."Template Code"));

            if RequestPageParametersHelper.ConvertParametersToFilters(SearchRecRef, TempBlob) then
                if SearchRecRef.Find() then
                    exit(ConfigTemplateHeader.Get(ConfigTmplSelectionRules."Template Code"));

        until ConfigTmplSelectionRules.Next() = 0;

        exit(false);
    end;
}

