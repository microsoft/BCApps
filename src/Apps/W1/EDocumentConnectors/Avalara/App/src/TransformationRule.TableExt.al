tableextension 6374 "Transformation Rule" extends "Transformation Rule"
{
    fields
    {
        field(6370; "Lookup Table ID"; Integer)
        {
            Caption = 'Lookup Table ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                if "Lookup Table ID" <> 0 then
                    CalcFields("Lookup Table Name");
            end;
        }
        field(6371; "Lookup Table Name"; Text[30])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Lookup Table ID")));
            Caption = 'Lookup Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6372; "Primary Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'Primary Field No. (Match Input)';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                FieldRec: Record Field;
            begin
                if "Lookup Table ID" = 0 then
                    Error('Please select a Lookup Table ID first.');

                FieldRec.SetRange(TableNo, "Lookup Table ID");
                FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
                if Page.RunModal(Page::"Fields Lookup", FieldRec) = Action::LookupOK then begin
                    "Primary Field No." := FieldRec."No.";
                    CalcFields("Primary Field Name");
                end;
            end;

            trigger OnValidate()
            begin
                if "Primary Field No." <> 0 then
                    CalcFields("Primary Field Name");
            end;
        }
        field(6373; "Primary Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Lookup Table ID"), "No." = field("Primary Field No.")));
            Caption = 'Primary Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6374; "Secondary Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'Secondary Field No. (Match Key)';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                FieldRec: Record Field;
            begin
                if "Lookup Table ID" = 0 then
                    Error('Please select a Lookup Table ID first.');

                FieldRec.SetRange(TableNo, "Lookup Table ID");
                FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
                if Page.RunModal(Page::"Fields Lookup", FieldRec) = Action::LookupOK then begin
                    "Secondary Field No." := FieldRec."No.";
                    CalcFields("Secondary Field Name");
                end;
            end;

            trigger OnValidate()
            begin
                if "Secondary Field No." <> 0 then
                    CalcFields("Secondary Field Name");
            end;
        }
        field(6375; "Secondary Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Lookup Table ID"), "No." = field("Secondary Field No.")));
            Caption = 'Secondary Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6376; "Secondary Filter Value"; Text[250])
        {
            Caption = 'Secondary Filter Value (Key)';
            DataClassification = CustomerContent;
        }
        field(6377; "Result Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'Result Field No. (Return Value)';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                FieldRec: Record Field;
            begin
                if "Lookup Table ID" = 0 then
                    Error('Please select a Lookup Table ID first.');

                FieldRec.SetRange(TableNo, "Lookup Table ID");
                FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
                if Page.RunModal(Page::"Fields Lookup", FieldRec) = Action::LookupOK then begin
                    "Result Field No." := FieldRec."No.";
                    CalcFields("Result Field Name");
                end;
            end;

            trigger OnValidate()
            begin
                if "Result Field No." <> 0 then
                    CalcFields("Result Field Name");
            end;
        }
        field(6378; "Result Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Lookup Table ID"), "No." = field("Result Field No.")));
            Caption = 'Result Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
