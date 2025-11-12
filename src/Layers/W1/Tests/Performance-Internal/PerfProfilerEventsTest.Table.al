table 132209 "Perf Profiler Events Test"
{
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
        }
        field(2; "Session ID"; Integer)
        {
        }
        field(3; Indentation; Integer)
        {
        }
        field(4; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = 'TableData,Table,Form,Report,Dataport,Codeunit,XMLport,MenuSuite,Page,Query,System,FieldNumber,PageExtension';
            OptionMembers = TableData,"Table",Form,"Report",Dataport,"Codeunit","XMLport",MenuSuite,"Page","Query",System,FieldNumber,"PageExtension";
        }
        field(5; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            TableRelation = AllObj."Object ID" where("Object Type" = field("Object Type"));
        }
        field(6; "Line No"; Integer)
        {
        }
        field(7; Statement; Text[1024])
        {
        }
        field(8; Duration; Decimal)
        {
            AutoFormatType = 0;
        }
        field(9; HitCount; Integer)
        {
        }
        field(10; Total; Decimal)
        {
            CalcFormula = sum("Perf Profiler Events Test".Duration where(Indentation = const(0),
                                                                          "Session ID" = field("Session ID"),
                                                                          Statement = filter(<> '*2000000207*User AL Code*' & <> '*2000000071*User AL Code*')));
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(11; "Total SQL Queries"; Integer)
        {
            CalcFormula = count("Perf Profiler Events Test" where("Object Type" = const(TableData),
                                                                   "Object ID" = const(0),
                                                                   "Session ID" = field("Session ID"),
                                                                    Statement = filter(<> '*2000000207*User AL Code*' & <> '*2000000071*User AL Code*')));
            FieldClass = FlowField;
        }
        field(12; "Total SQL Query Duration"; Decimal)
        {
            CalcFormula = sum("Perf Profiler Events Test".Duration where("Object Type" = const(TableData),
                                                                          "Object ID" = const(0),
                                                                          "Session ID" = field("Session ID"),
                                                                          Statement = filter(<> '*2000000207*User AL Code*' & <> '*2000000071*User AL Code*')));
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(13; "Total SQL Query Hit Count"; Integer)
        {
            CalcFormula = sum("Perf Profiler Events Test".HitCount where("Object Type" = const(TableData),
                                                                          "Object ID" = const(0),
                                                                          "Session ID" = field("Session ID"),
                                                                          Statement = filter(<> '*2000000207*User AL Code*' & <> '*2000000071*User AL Code*')));
            FieldClass = FlowField;
        }
        field(14; "Max SQL Query Duration"; Decimal)
        {
            CalcFormula = max("Perf Profiler Events Test".Duration where("Object Type" = const(TableData),
                                                                          "Object ID" = const(0),
                                                                          "Session ID" = field("Session ID"),
                                                                          Statement = filter(<> '*2000000207*User AL Code*' & <> '*2000000071*User AL Code*')));
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(15; "Max SQL Query Hit Count"; Integer)
        {
            CalcFormula = max("Perf Profiler Events Test".HitCount where("Object Type" = const(TableData),
                                                                          "Object ID" = const(0),
                                                                          "Session ID" = field("Session ID"),
                                                                          Statement = filter(<> '*2000000207*User AL Code*' & <> '*2000000071*User AL Code*')));
            FieldClass = FlowField;
        }
        field(16; "Event Type"; Option)
        {
            OptionCaption = ',SqlExecuteScalar,SqlExecuteNonQuery,SqlExecuteReader,SqlReadNextResult,SqlReadNextRow,SqlBeginTransaction,SqlPrepare,SqlOpenConnection,SqlCommit,SqlRollback';
            OptionMembers = ,SqlExecuteScalar,SqlExecuteNonQuery,SqlExecuteReader,SqlReadNextResult,SqlReadNextRow,SqlBeginTransaction,SqlPrepare,SqlOpenConnection,SqlCommit,SqlRollback;
        }

        field(17; "Original Type"; Option)
        {
            OptionCaption = 'StartMethod,StopMethod,Statement,None';
            OptionMembers = StartMethod,StopMethod,Statement,None;
        }

        field(18; "Sub Type"; Option)
        {
            OptionCaption = 'SqlEvent,AlEvent,SystemEvent,None';
            OptionMembers = SqlEvent,AlEvent,SystemEvent,None;
        }

        field(19; "IsALEvent"; Boolean)
        {
        }
        field(20; "Total MD SQL Queries"; Integer)
        {
            CalcFormula = count("Perf Profiler Events Test" where("Object Type" = const(TableData),
                                                                   "Object ID" = const(0),
                                                                   "Session ID" = field("Session ID"),
                                                                    Statement = filter('*2000000207*User AL Code*' | '*2000000071*User AL Code*')));
            FieldClass = FlowField;
        }
        field(21; "Total MD SQL Query Hit Count"; Integer)
        {
            CalcFormula = sum("Perf Profiler Events Test".HitCount where("Object Type" = const(TableData),
                                                                          "Object ID" = const(0),
                                                                          "Session ID" = field("Session ID"),
                                                                          Statement = filter('*2000000207*User AL Code*' | '*2000000071*User AL Code*')));
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Id, "Session ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
