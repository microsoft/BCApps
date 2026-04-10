// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;

query 3691 "Production BOM & Line Details"
{
    QueryType = Normal;
    OrderBy = ascending(No_);

    elements
    {
        dataitem(Production_BOM_Header; "Production BOM Header")
        {
            column(No_; "No.")
            {
            }
            column(Status; Status)
            {
            }
            column(Low_Level_Code; "Low-Level Code")
            {
            }

            dataitem(Production_BOM_Line; "Production BOM Line")
            {
                DataItemLink = "Production BOM No." = Production_BOM_Header."No.";
                SqlJoinType = InnerJoin;

                column(Type; Type)
                {
                }
                column(Child_No_; "No.")
                {
                }
                column(Version_Code; "Version Code")
                {
                }

                dataitem(ChildItem; Item)
                {
                    DataItemLink = "No." = Production_BOM_Line."No.";
                    SqlJoinType = LeftOuterJoin;

                    column(ChildItem_No_; "No.")
                    {
                    }

                    column(ChildItem_Low_Level_Code; "Low-Level Code")
                    {
                    }

                    dataitem(ChildBOM; "Production BOM Header")
                    {
                        DataItemLink = "No." = Production_BOM_Line."No.";
                        SqlJoinType = LeftOuterJoin;

                        column(ChildBOM_No_; "No.")
                        {
                        }

                        column(ChildBOM_Low_Level_Code; "Low-Level Code")
                        {
                        }

                        column(ChildBOM_Status; Status)
                        {
                        }

                        dataitem(Production_BOM_Version; "Production BOM Version")
                        {
                            DataItemLink = "Production BOM No." = Production_BOM_Header."No.", "Version Code" = Production_BOM_Line."Version Code";
                            SqlJoinType = LeftOuterJoin;

                            column(BOM_Version_Code; "Version Code")
                            {
                            }

                            column(BOM_Version_Status; Status)
                            {
                            }

                            column(BOM_Version_StartingDate; "Starting Date")
                            {
                            }
                        }
                    }

                }
            }
        }
    }
}
