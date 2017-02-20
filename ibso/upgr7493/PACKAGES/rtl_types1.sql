prompt rtl_types 
create or replace package
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rtl_types1.sql $<br/>
 *  $Author: fayzulin $<br/>
 *  $Revision: 93694 $<br/>
 *  $Date:: 2016-02-11 08:39:43 #$<br/>
 *  @headcom
 */

rtl_types is 

/*
  ��� ��������� ��������� NVarchar2:
  1. � ������������ ������ ���������������� ������ � ������������ ���� VALUE_TYPE ��� nvarchar2(2000)
  2. � ������������ ������ ��������������� ������ � ������������ ���� VALUE_TYPE ��� varchar2(4000)
  3. � ���� ������ � ���� ��������� get_value_type ���������������� ������ � ���������� return, ������������ ��������� VALUE_TYPE_NVARCHAR2
  4. � ���� ������ � ���� ��������� get_value_type ��������������� ������ � ���������� return, ������������ ��������� VALUE_TYPE_VARCHAR2
  5. ���������������� ������������ � ���� ������
  6. ��� �������������, ���������������� ��� �������, ������� ������� �� ������ RTL_TYPES

  ��� ���������� ��������� NVarchar2:
  1. � ������������ ������ ���������������� ������ � ������������ ���� VALUE_TYPE ��� varchar2(4000)
  2. � ������������ ������ ��������������� ������ � ������������ ���� VALUE_TYPE ��� nvarchar2(2000)
  3. � ���� ������ � ���� ��������� get_value_type ���������������� ������ � ���������� return, ������������ ��������� VALUE_TYPE_VARCHAR2
  4. � ���� ������ � ���� ��������� get_value_type ��������������� ������ � ���������� return, ������������ ��������� VALUE_TYPE_NVARCHAR2
  5. ���������������� ������������ � ���� ������
  6. ��� �������������, ���������������� ��� �������, ������� ������� �� ������ RTL_TYPES
*/

    /* ��� ������ ��������, ����������/��������������� ��������� runtime �� */
    subtype VALUE_TYPE is varchar2(4000);  -- ��������� nvarchar2 ���������
    -- subtype VALUE_TYPE is nvarchar2(2000);   -- ��������� nvarchar2 ��������

    /* ������� ���������� ��� ������ ��������, ����������/��������������� ��������� runtime �� ( VARCHAR2 / NVARCHAR2 )*/
    function get_value_type return varchar2;

end rtl_types;
/
show errors package rtl_types
