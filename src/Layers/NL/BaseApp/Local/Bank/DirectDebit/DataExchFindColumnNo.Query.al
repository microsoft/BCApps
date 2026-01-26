// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using System.IO;

query 11400 "Data Exch. Find Column No."
{
    Caption = 'Data Exch. Find Column No.';

    elements
    {
        dataitem(Data_Exch_Line_Def; "Data Exch. Line Def")
        {
            dataitem(Data_Exch_Column_Def; "Data Exch. Column Def")
            {
                DataItemLink = "Data Exch. Def Code" = Data_Exch_Line_Def."Data Exch. Def Code", "Data Exch. Line Def Code" = Data_Exch_Line_Def.Code;
                SqlJoinType = InnerJoin;
                column(Data_Exch_Def_Code; "Data Exch. Def Code")
                {
                }
                column(Data_Exch_Line_Def_Code; "Data Exch. Line Def Code")
                {
                }
                column(Path; Path)
                {
                }
                column(Column_No; "Column No.")
                {
                }
            }
        }
    }
}

