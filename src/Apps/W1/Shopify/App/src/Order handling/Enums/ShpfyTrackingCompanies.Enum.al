// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Enum Shpfy Tracking Companies (ID 30122).
/// Represented by https://shopify.dev/docs/api/admin-graphql/latest/objects/Fulfillment#field-Fulfillment.fields.trackingInfo.company
/// </summary>
enum 30122 "Shpfy Tracking Companies"
{
    Caption = 'Shopify Tracking Companies';
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "4PX")
    {
        Caption = '4PX';
    }
    value(2; APC)
    {
        Caption = 'APC';
    }
    value(3; "Amazon Logistics UK")
    {
        Caption = 'Amazon Logistics UK';
    }
    value(4; "Amazon Logistics US")
    {
        Caption = 'Amazon Logistics US';
    }
    value(5; "Anjun Logistics")
    {
        Caption = 'Anjun Logistics';
    }
    value(6; "Australia Post")
    {
        Caption = 'Australia Post';
    }
    value(7; Bluedart)
    {
        Caption = 'Bluedart';
    }
    value(8; "Canada Post")
    {
        Caption = 'Canada Post';
    }
    value(9; Canpar)
    {
        Caption = 'Canpar';
    }
    value(10; "China Post")
    {
        Caption = 'China Post';
    }
    value(11; Chukou1)
    {
        Caption = 'Chukou1';
    }
    value(12; Correios)
    {
        Caption = 'Correios';
    }
    value(13; "DHL Express")
    {
        Caption = 'DHL Express';
    }
    value(14; "DHL eCommerce")
    {
        Caption = 'DHL eCommerce';
    }
    value(15; "DHL eCommerce Asia")
    {
        Caption = 'DHL eCommerce Asia';
    }
    value(16; DPD)
    {
        Caption = 'DPD';
    }
    value(17; "DPD Local")
    {
        Caption = 'DPD Local';
    }
    value(18; "DPD UK")
    {
        Caption = 'DPD UK';
    }
    value(19; Delhivery)
    {
        Caption = 'Delhivery';
    }
    value(20; Eagle)
    {
        Caption = 'Eagle';
    }
    value(21; FSC)
    {
        Caption = 'FSC';
    }
    value(22; FedEx)
    {
        Caption = 'FedEx';
    }
    value(23; GLS)
    {
        Caption = 'GLS';
    }
    value(24; "GLS (US)")
    {
        Caption = 'GLS (US)';
    }
    value(25; Globegistics)
    {
        Caption = 'Globegistics';
    }
    value(26; "Japan POST (EN)")
    {
        Caption = 'Japan POST (EN)';
    }
    value(27; "Japan POST (JA)")
    {
        Caption = 'Japan POST (JA)';
    }
    value(28; "La Poste")
    {
        Caption = 'La Poste';
    }
    value(29; "New Zeeland Post")
    {
        Caption = 'New Zealand Post';
    }
    value(30; Newgistics)
    {
        Caption = 'Newgistics';
    }
    value(31; PostNL)
    {
        Caption = 'PostNL';
    }
    value(32; PostNord)
    {
        Caption = 'PostNord';
    }
    value(33; Purolator)
    {
        Caption = 'Purolator';
    }
    value(34; "Royal Mail")
    {
        Caption = 'Royal Mail';
    }
    value(35; "SF Express")
    {
        Caption = 'SF Express';
    }
    value(36; "SFC Fulfillment")
    {
        Caption = 'SFC Fulfillment';
    }
    value(37; "Sagawa (EN)")
    {
        Caption = 'Sagawa (EN)';
    }
    value(38; "Sagawa (JA)")
    {
        Caption = 'Sagawa (JA)';
    }
    value(39; Sendle)
    {
        Caption = 'Sendle';
    }
    value(40; "Singapore Post")
    {
        Caption = 'Singapore Post';
    }
    value(41; TNT)
    {
        Caption = 'TNT';
    }
    value(42; UPS)
    {
        Caption = 'UPS';
    }
    value(43; USPS)
    {
        Caption = 'USPS';
    }
    value(44; Whistl)
    {
        Caption = 'Whistl';
    }
    value(45; "Yamato (EN)")
    {
        Caption = 'Yamato (EN)';
    }
    value(46; "Yamato (JA)")
    {
        Caption = 'Yamato (JA)';
    }
    value(47; YunExpress)
    {
        Caption = 'YunExpress';
    }
    value(48; Other)
    {
        Caption = 'Other';
    }
    value(49; AGS)
    {
        Caption = 'AGS';
    }
    value(50; Amazon)
    {
        Caption = 'Amazon';
    }
    value(51; "An Post")
    {
        Caption = 'An Post';
    }
    value(52; "Asendia USA")
    {
        Caption = 'Asendia USA';
    }
    value(53; Bonshaw)
    {
        Caption = 'Bonshaw';
    }
    value(54; BPost)
    {
        Caption = 'BPost';
    }
    value(55; "BPost International")
    {
        Caption = 'BPost International';
    }
    value(56; "CDL Last Mile")
    {
        Caption = 'CDL Last Mile';
    }
    value(57; Chronopost)
    {
        Caption = 'Chronopost';
    }
    value(58; Colissimo)
    {
        Caption = 'Colissimo';
    }
    value(59; Comingle)
    {
        Caption = 'Comingle';
    }
    value(60; Coordinadora)
    {
        Caption = 'Coordinadora';
    }
    value(61; Correos)
    {
        Caption = 'Correos';
    }
    value(62; CTT)
    {
        Caption = 'CTT';
    }
    value(63; "CTT Express")
    {
        Caption = 'CTT Express';
    }
    value(64; "Cyprus Post")
    {
        Caption = 'Cyprus Post';
    }
    value(65; Delnext)
    {
        Caption = 'Delnext';
    }
    value(66; "Deutsche Post")
    {
        Caption = 'Deutsche Post';
    }
    value(67; "DTD Express")
    {
        Caption = 'DTD Express';
    }
    value(68; DX)
    {
        Caption = 'DX';
    }
    value(69; Estes)
    {
        Caption = 'Estes';
    }
    value(70; Evri)
    {
        Caption = 'Evri';
    }
    value(71; "First Global Logistics")
    {
        Caption = 'First Global Logistics';
    }
    value(72; "First Line")
    {
        Caption = 'First Line';
    }
    value(73; Fulfilla)
    {
        Caption = 'Fulfilla';
    }
    value(74; "Guangdong Weisuyi Information Technology (WSE)")
    {
        Caption = 'Guangdong Weisuyi Information Technology (WSE)';
    }
    value(75; "Heppner Internationale Spedition GmbH & Co.")
    {
        Caption = 'Heppner Internationale Spedition GmbH & Co.';
    }
    value(76; "Iceland Post")
    {
        Caption = 'Iceland Post';
    }
    value(77; IDEX)
    {
        Caption = 'IDEX';
    }
    value(78; "Israel Post")
    {
        Caption = 'Israel Post';
    }
    value(79; "La Poste Burkina Faso")
    {
        Caption = 'La Poste Burkina Faso';
    }
    value(80; "La Poste Colissimo")
    {
        Caption = 'La Poste Colissimo';
    }
    value(81; Lasership)
    {
        Caption = 'Lasership';
    }
    value(82; "Latvia Post")
    {
        Caption = 'Latvia Post';
    }
    value(83; "Lietuvos Pastas")
    {
        Caption = 'Lietuvos Paštas';
    }
    value(84; Logisters)
    {
        Caption = 'Logisters';
    }
    value(85; "Lone Star Overnight")
    {
        Caption = 'Lone Star Overnight';
    }
    value(86; "M3 Logistics")
    {
        Caption = 'M3 Logistics';
    }
    value(87; "Meteor Space")
    {
        Caption = 'Meteor Space';
    }
    value(88; "Mondial Relay")
    {
        Caption = 'Mondial Relay';
    }
    value(89; NinjaVan)
    {
        Caption = 'NinjaVan';
    }
    value(90; "North Russia Supply Chain (Shenzhen) Co.")
    {
        Caption = 'North Russia Supply Chain (Shenzhen) Co.';
    }
    value(91; OnTrac)
    {
        Caption = 'OnTrac';
    }
    value(92; Packeta)
    {
        Caption = 'Packeta';
    }
    value(93; "Pago Logistics")
    {
        Caption = 'Pago Logistics';
    }
    value(94; "Ping An Da Tengfei Express")
    {
        Caption = 'Ping An Da Tengfei Express';
    }
    value(95; "Pitney Bowes")
    {
        Caption = 'Pitney Bowes';
    }
    value(96; "Portal PostNord")
    {
        Caption = 'Portal PostNord';
    }
    value(97; "Poste Italiane")
    {
        Caption = 'Poste Italiane';
    }
    value(98; "PostNord DK")
    {
        Caption = 'PostNord DK';
    }
    value(99; "PostNord NO")
    {
        Caption = 'PostNord NO';
    }
    value(100; "PostNord SE")
    {
        Caption = 'PostNord SE';
    }
    value(101; Qxpress)
    {
        Caption = 'Qxpress';
    }
    value(102; "Qyun Express")
    {
        Caption = 'Qyun Express';
    }
    value(103; "Royal Shipments")
    {
        Caption = 'Royal Shipments';
    }
    value(104; "SHREE NANDAN COURIER")
    {
        Caption = 'SHREE NANDAN COURIER';
    }
    value(105; "Southwest Air Cargo")
    {
        Caption = 'Southwest Air Cargo';
    }
    value(106; StarTrack)
    {
        Caption = 'StarTrack';
    }
    value(107; "Step Forward Freight")
    {
        Caption = 'Step Forward Freight';
    }
    value(108; "Swiss Post")
    {
        Caption = 'Swiss Post';
    }
    value(109; "TForce Final Mile")
    {
        Caption = 'TForce Final Mile';
    }
    value(110; Tinghao)
    {
        Caption = 'Tinghao';
    }
    value(111; "Toll IPEC")
    {
        Caption = 'Toll IPEC';
    }
    value(112; "United Delivery Service")
    {
        Caption = 'United Delivery Service';
    }
    value(113; Venipak)
    {
        Caption = 'Venipak';
    }
    value(114; "We Post")
    {
        Caption = 'We Post';
    }
    value(115; Wizmo)
    {
        Caption = 'Wizmo';
    }
    value(116; WMYC)
    {
        Caption = 'WMYC';
    }
    value(117; Xpedigo)
    {
        Caption = 'Xpedigo';
    }
    value(118; "XPO Logistics")
    {
        Caption = 'XPO Logistics';
    }
    value(119; "YiFan Express")
    {
        Caption = 'YiFan Express';
    }
}
