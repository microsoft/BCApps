namespace System.Security.AccessControl;

permissionset 2917 "D365 FINANCE"
{
    Assignable = true;

    Caption = 'Read and write finance data';

    IncludedPermissionSets = "D365 ACC. RECEIVABLE",
                             "D365 BANKING",
                             "D365 BASIC",
                             "D365 CASH FLOW",
                             "D365 COSTACC, EDIT",
                             "D365 COSTACC, SETUP",
                             "D365 COSTACC, VIEW",
                             "D365 FA, EDIT",
                             "D365 FA, SETUP",
                             "D365 FA, VIEW",
                             "D365 FINANCIAL REP.",
                             "D365 HR, EDIT",
                             "D365 HR, SETUP",
                             "D365 HR, VIEW",
                             "D365 IC, EDIT",
                             "D365 IC, SETUP",
                             "D365 IC, VIEW",
                             "D365 INV DOC, CREATE",
                             "D365 INV DOC, POST",
                             "D365 INV, SETUP",
                             "D365 JOBS, EDIT",
                             "D365 JOURNALS, EDIT",
                             "D365 JOURNALS, POST",
                             "D365 SETUP";
}