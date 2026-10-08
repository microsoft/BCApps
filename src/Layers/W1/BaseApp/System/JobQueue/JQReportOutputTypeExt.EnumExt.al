namespace System.Threading;

#pragma warning disable PTE0023 // Allow using numbers outside PTE range
enumextension 482 "JQ Report Output Type Ext" extends "Job Queue Report Output Type"
{
    value(0; "PDF")
    {
        Implementation = "Job Queue Report Runner" = "Job Queue Start Report";
        Caption = 'PDF';
    }
    value(1; "Word")
    {
        Implementation = "Job Queue Report Runner" = "Job Queue Start Report";
        Caption = 'Word';
    }
    value(2; "Excel")
    {
        Implementation = "Job Queue Report Runner" = "Job Queue Start Report";
        Caption = 'Excel';
    }
    value(3; "Print")
    {
        Implementation = "Job Queue Report Runner" = "Job Queue Start Report";
        Caption = 'Print';
    }
}
