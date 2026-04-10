namespace System.Security.AccessControl;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

permissionset 7561 "Manufacturing CRP - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Setup CRP';

    Permissions = tabledata "Capacity Constrained Resource" = RIMD,
                  tabledata "Capacity Unit of Measure" = RIMD,
                  tabledata "Quality Measure" = RIMD,
                  tabledata "Routing Link" = RIMD,
                  tabledata Scrap = RIMD,
                  tabledata "Shop Calendar" = RIMD,
                  tabledata "Shop Calendar Holiday" = RIMD,
                  tabledata "Shop Calendar Working Days" = RIMD,
                  tabledata "Standard Task" = RIMD,
                  tabledata "Standard Task Description" = RIMD,
                  tabledata "Standard Task Personnel" = RIMD,
                  tabledata "Standard Task Quality Measure" = RIMD,
                  tabledata "Standard Task Tool" = RIMD,
                  tabledata Stop = RIMD,
                  tabledata "Work Center Group" = RIMD,
                  tabledata "Work Shift" = RIMD;
}
