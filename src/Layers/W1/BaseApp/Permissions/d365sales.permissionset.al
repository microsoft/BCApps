namespace System.Security.AccessControl;

permissionset 2918 "D365 SALES"
{
    Assignable = true;

    Caption = 'Post sales documents';

    IncludedPermissionSets = "D365 ASSEMBLY, EDIT",
                             "D365 ASSEMBLY, VIEW",
                             "D365 BASIC",
                             "D365 COSTACC, EDIT",
                             "D365 COSTACC, VIEW",
                             "D365 CUSTOMER, EDIT",
                             "D365 CUSTOMER, VIEW",
                             "D365 DYN CRM MGT",
                             "D365 IC, EDIT",
                             "D365 IC, VIEW",
                             "D365 ITEM, EDIT",
                             "D365 ITEM, VIEW",
                             "D365 ITEM AVAIL CALC",
                             "D365 JOBS, EDIT",
                             "D365 SALES DOC, EDIT",
                             "D365 SALES DOC, POST";
}