/*
 * # Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
*/
CREATE TABLE "BLUADMIN"."NYC_FREE_PUBLIC_WIFI"  (
            "THE_GEOM" VARCHAR(45 OCTETS) ,
            "OBJECTID" SMALLINT ,
            "BORO" VARCHAR(2 OCTETS) ,
            "TYPE" VARCHAR(12 OCTETS) ,
            "PROVIDER" VARCHAR(23 OCTETS) ,
            "NAME" VARCHAR(100 OCTETS) ,
            "LOCATION" VARCHAR(100 OCTETS) ,
            "LAT" DECIMAL(22,10) ,
            "LON" DECIMAL(22,10) ,
            "X" DECIMAL(18,6) ,
            "Y" DECIMAL(18,6) ,
            "LOCATION_T" VARCHAR(100 OCTETS) ,
            "REMARKS" VARCHAR(48 OCTETS) ,
            "CITY" VARCHAR(16 OCTETS) ,
            "SSID" VARCHAR(24 OCTETS) ,
            "SOURCEID" VARCHAR(22 OCTETS) ,
            "ACTIVATED" VARCHAR(28 OCTETS) ,
            "BOROCODE" SMALLINT ,
            "BORONAME" VARCHAR(13 OCTETS) ,
            "NTACODE" VARCHAR(4 OCTETS) ,
            "NTANAME" VARCHAR(100 OCTETS) ,
            "COUNDIST" SMALLINT ,
            "POSTCODE" SMALLINT ,
            "BOROCD" SMALLINT ,
            "CT2010" INTEGER ,
            "BOROCT2010" INTEGER ,
            "BIN" INTEGER ,
            "BBL" BIGINT ,
            "DOITT_ID" SMALLINT )
            DISTRIBUTE BY HASH("BBL",
            "CT2010",
            "BOROCT2010")
            IN "USERSPACE1"
            ORGANIZE BY COLUMN
