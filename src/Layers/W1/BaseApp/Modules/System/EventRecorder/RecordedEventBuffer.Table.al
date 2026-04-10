namespace System.Tooling;

using System.Reflection;

table 9804 "Recorded Event Buffer"
{
    Caption = 'Recorded Event Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Session ID"; Integer)
        {
            Caption = 'Session ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Object Type"; Option)
        {
            Caption = 'Object Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
            OptionMembers = "Table Data","Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        }
        field(3; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            DataClassification = SystemMetadata;
            TableRelation = if ("Object Type" = const("Table Data")) AllObj."Object ID" where("Object Type" = const(Table))
            else
            if ("Object Type" = const(Table)) AllObj."Object ID" where("Object Type" = const(Table))
            else
            if ("Object Type" = const(Report)) AllObj."Object ID" where("Object Type" = const(Report))
            else
            if ("Object Type" = const(Codeunit)) AllObj."Object ID" where("Object Type" = const(Codeunit))
            else
            if ("Object Type" = const(XMLport)) AllObj."Object ID" where("Object Type" = const(XMLport))
            else
            if ("Object Type" = const(MenuSuite)) AllObj."Object ID" where("Object Type" = const(MenuSuite))
            else
            if ("Object Type" = const(Page)) AllObj."Object ID" where("Object Type" = const(Page))
            else
            if ("Object Type" = const(Query)) AllObj."Object ID" where("Object Type" = const(Query))
            else
            if ("Object Type" = const(System)) AllObj."Object ID" where("Object Type" = const(System));
        }
        field(4; "Object Name"; Text[30])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = field("Object Type"),
                                                                        "Object ID" = field("Object ID")));
            Caption = 'Object Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Event Name"; Text[129])
        {
            Caption = 'Event Name';
            DataClassification = SystemMetadata;
        }
        field(6; "Event Type"; Option)
        {
            Caption = 'Event Type';
            DataClassification = SystemMetadata;
            OptionCaption = ',Custom Event,Trigger Event';
            OptionMembers = ,"Custom Event","Trigger Event";
        }
        field(7; "Call Order"; Integer)
        {
            Caption = 'Call Order';
            DataClassification = SystemMetadata;
        }
        field(8; "Element Name"; Text[120])
        {
            Caption = 'Element Name';
            DataClassification = SystemMetadata;
        }
        field(9; "Calling Object Type"; Option)
        {
            Caption = 'Calling Object Type';
            DataClassification = SystemMetadata;
            OptionCaption = ',Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System';
            OptionMembers = ,"Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",System;
        }
        field(10; "Calling Object ID"; Integer)
        {
            Caption = 'Calling Object ID';
            DataClassification = SystemMetadata;
        }
        field(11; "Calling Object Name"; Text[30])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = field("Calling Object Type"),
                                                                        "Object ID" = field("Calling Object ID")));
            Caption = 'Calling Object Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Calling Method"; Text[129])
        {
            Caption = 'Calling Method';
            DataClassification = SystemMetadata;
        }
        field(13; "Hit Count"; Integer)
        {
            Caption = 'Hit Count';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Object Type", "Object ID", "Event Name", "Element Name", "Event Type", "Calling Object Type", "Calling Object ID", "Calling Method", "Call Order")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

