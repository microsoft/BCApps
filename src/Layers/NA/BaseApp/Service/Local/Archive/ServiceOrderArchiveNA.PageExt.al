// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

pageextension 10011 "Service Order Archive NA" extends "Service Order Archive"
{
    layout
    {
        addlast(General)
        {
            field("CFDI Purpose"; Rec."CFDI Purpose")
            {
                ApplicationArea = BasicMX;
                Importance = Additional;
                ToolTip = 'Specifies the CFDI purpose required for reporting to the Mexican tax authorities (SAT).';
            }
            field("CFDI Relation"; Rec."CFDI Relation")
            {
                ApplicationArea = BasicMX;
                Importance = Additional;
                ToolTip = 'Specifies the relation of the CFDI document. ';
            }
            field("CFDI Export Code"; Rec."CFDI Export Code")
            {
                ApplicationArea = BasicMX;
                ToolTip = 'Specifies a code to indicate if the document is used for exports to other countries.';
            }
            field("CFDI Period"; Rec."CFDI Period")
            {
                ApplicationArea = BasicMX;
                ToolTip = 'Specifies the period to use when reporting for general public customers';
            }
            field("CFDI Certificate of Origin No."; Rec."CFDI Certificate of Origin No.")
            {
                ApplicationArea = BasicMX;
                ToolTip = 'Specifies the identifier which was used to pay for the issuance of the certificate of origin.';
            }
        }
        addafter(" Foreign Trade")
        {
            group(ElectronicDocument)
            {
                Caption = 'Electronic Document';
                field("SAT Address ID"; Rec."SAT Address ID")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT address that the goods or merchandise are moved to.';
                    BlankZero = true;
                }
                field("Foreign Trade MX"; Rec."Foreign Trade")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies whether the goods or merchandise that are transported enter or leave the national territory.';
                }
                field("SAT International Trade Term"; Rec."SAT International Trade Term")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies an international commercial terms code that are used in international sale contracts according to the SAT internatoinal trade terms definition.';
                }
                field("Exchange Rate USD"; Rec."Exchange Rate USD")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the USD to MXN exchange rate that is used to report foreign trade documents to Mexican SAT authorities. This rate must match the rate used by the Mexican National Bank.';
                }
            }
        }
    }
}