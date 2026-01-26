codeunit 161406 "Create Digital Audit Data"
{

    trigger OnRun()
    begin
        // 11002 - Digital Audit Definition Group
        InsertDataDef(XEXPORT1, XDefinitionGroupforEXPORT1);

        // 11007 - Digital Audit Record Code
        InsertDataRecord(XRECORD1, XRecordCode1);

        // 11003 - Digital Audit Record Definition
        InsertDataRecordDef(XEXPORT1, XRECORD1, XRecordCode11);

        // 11004 - Digital Audit Record Def. Table
        InsertDataRecordDefTable(XEXPORT1, XRECORD1, 15, 0, 0, 0, 0, 10000, XGLAccounttxt);
        InsertDataRecordDefTable(XEXPORT1, XRECORD1, 17, 1, 10000, 15, 4, 20000, XGLEntrytxt);
        InsertDataRecordDefTable(XEXPORT1, XRECORD1, 18, 0, 0, 0, 0, 30000, XCustomertxt);
        InsertDataRecordDefTable(XEXPORT1, XRECORD1, 21, 1, 30000, 18, 4, 40000, XCustLedgertxt);
        InsertDataRecordDefTable(XEXPORT1, XRECORD1, 23, 0, 0, 0, 0, 50000, XVendortxt);
        InsertDataRecordDefTable(XEXPORT1, XRECORD1, 25, 1, 50000, 23, 4, 60000, XVendLedgertxt);
        InsertDataRecordDefTable(XEXPORT1, XRECORD1, 254, 0, 0, 0, 4, 70000, XVATEntrytxt);

        // 11005 - Digital Audit Record Def. Field
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 10000, 15, 1, 10000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 10000, 15, 2, 20000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 10000, 15, 4, 30000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 10000, 15, 10, 40000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 10000, 15, 31, 50000, 2);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 10000, 15, 32, 60000, 1);

        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 1, 10000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 3, 20000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 4, 30000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 5, 40000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 6, 50000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 7, 60000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 17, 70000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 52, 80000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 53, 90000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 54, 100000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 20000, 17, 56, 110000, 0);

        InsertDataRecordDefField(XEXPORT1, XRECORD1, 30000, 18, 1, 10000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 30000, 18, 2, 20000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 30000, 18, 21, 30000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 30000, 18, 59, 40000, 2);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 30000, 18, 61, 50000, 1);

        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 1, 10000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 3, 20000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 4, 30000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 5, 40000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 6, 50000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 7, 60000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 11, 70000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 13, 80000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 14, 90000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 15, 100000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 40000, 21, 16, 110000, 0);

        InsertDataRecordDefField(XEXPORT1, XRECORD1, 50000, 23, 1, 10000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 50000, 23, 2, 20000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 50000, 23, 21, 30000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 50000, 23, 59, 40000, 2);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 50000, 23, 61, 50000, 1);

        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 1, 10000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 3, 20000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 4, 30000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 5, 40000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 6, 50000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 7, 60000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 11, 70000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 13, 80000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 14, 90000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 15, 100000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 60000, 25, 16, 110000, 0);

        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 1, 10000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 4, 20000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 5, 30000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 6, 40000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 7, 50000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 8, 60000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 9, 70000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 10, 80000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 2, 90000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 3, 100000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 39, 110000, 0);
        InsertDataRecordDefField(XEXPORT1, XRECORD1, 70000, 254, 40, 120000, 0);

        // 11006 - Digital Audit Table Relation
        InsertDataTableRelation(XEXPORT1, XRECORD1, 15, 1, 17, 3);
        InsertDataTableRelation(XEXPORT1, XRECORD1, 18, 1, 21, 3);
        InsertDataTableRelation(XEXPORT1, XRECORD1, 23, 1, 25, 3);
    end;

    var
        XEXPORT1: Label 'EXPORT-1';
        XDefinitionGroupforEXPORT1: Label 'Definition Group for EXPORT-1';
        XRECORD1: Label 'RECORD-1';
        XRecordCode1: Label 'Record Code 1';
        XRecordCode11: Label 'Record Code 1';
        XGLAccounttxt: Label 'GL_Account.txt';
        XGLEntrytxt: Label 'GL_Entry.txt';
        XCustomertxt: Label 'Customer.txt';
        XCustLedgertxt: Label 'Cust_Ledger.txt';
        XVendortxt: Label 'Vendor.txt';
        XVendLedgertxt: Label 'Vend_Ledger.txt';
        XVATEntrytxt: Label 'VAT_Entry.txt';

    procedure InsertDataDef(NewCode: Code[10]; NewDescription: Text[50])
    var
        DataExport: Record "Data Export";
    begin
        DataExport.Init();
        DataExport.Validate(Code, NewCode);
        DataExport.Validate(Description, NewDescription);
        DataExport.Insert();
    end;

    procedure InsertDataRecord(NewCode: Code[10]; NewDescription: Text[50])
    var
        DataExportRecordType: Record "Data Export Record Type";
    begin
        DataExportRecordType.Init();
        DataExportRecordType.Validate(Code, NewCode);
        DataExportRecordType.Validate(Description, NewDescription);
        DataExportRecordType.Insert();
    end;

    procedure InsertDataRecordDef(GroupCode: Code[10]; RecordCode: Code[10]; NewDescription: Text[50])
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        DataExportRecordDefinition.Init();
        DataExportRecordDefinition.Validate("Data Export Code", GroupCode);
        DataExportRecordDefinition.Validate("Data Exp. Rec. Type Code", RecordCode);
        DataExportRecordDefinition.Validate(Description, NewDescription);
        DataExportRecordDefinition.Insert();
    end;

    procedure InsertDataRecordDefTable(GroupCode: Code[10]; RecordCode: Code[10]; TableNo: Integer; NewIndentation: Integer; RelationToLineNo: Integer; RelationToTableNo: Integer; PeriodFieldNo: Integer; LineNo: Integer; Filename: Text[250])
    var
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        DataExportRecordSource.Init();
        DataExportRecordSource.Validate("Data Export Code", GroupCode);
        DataExportRecordSource.Validate("Data Exp. Rec. Type Code", RecordCode);
        DataExportRecordSource.Validate("Table No.", TableNo);
        DataExportRecordSource.Indentation := NewIndentation;
        DataExportRecordSource."Relation To Table No." := RelationToTableNo;
        DataExportRecordSource."Relation To Line No." := RelationToLineNo;
        DataExportRecordSource.Validate("Period Field No.", PeriodFieldNo);
        DataExportRecordSource.Validate("Line No.", LineNo);
        DataExportRecordSource.Validate("Export File Name", Filename);
        DataExportRecordSource.Insert();
    end;

    procedure InsertDataRecordDefField(GroupCode: Code[10]; RecordCode: Code[10]; SourceLineNo: Integer; TableNo: Integer; FieldId: Integer; LineNo: Integer; DateFilterHandling: Integer)
    var
        DataExportRecordField: Record "Data Export Record Field";
    begin
        DataExportRecordField.Init();
        DataExportRecordField.Validate("Data Export Code", GroupCode);
        DataExportRecordField.Validate("Data Exp. Rec. Type Code", RecordCode);
        DataExportRecordField.Validate("Source Line No.", SourceLineNo);
        DataExportRecordField.Validate("Table No.", TableNo);
        DataExportRecordField.Validate("Field No.", FieldId);
        DataExportRecordField.Validate("Line No.", LineNo);
        if DateFilterHandling <> 0 then
            DataExportRecordField.Validate("Date Filter Handling", DateFilterHandling);
        DataExportRecordField.Insert();
    end;

    procedure InsertDataTableRelation(GroupCode: Code[10]; RecordCode: Code[10]; FromTableNo: Integer; FromFieldNo: Integer; ToTableNo: Integer; ToFieldNo: Integer)
    var
        DataExportTableRelation: Record "Data Export Table Relation";
    begin
        DataExportTableRelation.Init();
        DataExportTableRelation.Validate("Data Export Code", GroupCode);
        DataExportTableRelation.Validate("Data Exp. Rec. Type Code", RecordCode);
        DataExportTableRelation.Validate("From Table No.", FromTableNo);
        DataExportTableRelation.Validate("From Field No.", FromFieldNo);
        DataExportTableRelation.Validate("To Table No.", ToTableNo);
        DataExportTableRelation.Validate("To Field No.", ToFieldNo);
        DataExportTableRelation.Insert();
    end;
}

