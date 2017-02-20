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
  Для ВКЛЮЧЕНИЯ поддержки NVarchar2:
  1. В спецификации пакета раскомментируйте строку с определением типа VALUE_TYPE как nvarchar2(2000)
  2. В спецификации пакета закомментируйте строку с определением типа VALUE_TYPE как varchar2(4000)
  3. В теле пакета в теле процедуры get_value_type раскомментируйте строку с оператором return, возвращающим константу VALUE_TYPE_NVARCHAR2
  4. В теле пакета в теле процедуры get_value_type закомментируйте строку с оператором return, возвращающим константу VALUE_TYPE_VARCHAR2
  5. Перекомпилируйте спецификацию и тело пакета
  6. При необходимости, перекомпилируйте все объекты, которые зависят от пакета RTL_TYPES

  Для ВЫКЛЮЧЕНИЯ поддержки NVarchar2:
  1. В спецификации пакета раскомментируйте строку с определением типа VALUE_TYPE как varchar2(4000)
  2. В спецификации пакета закомментируйте строку с определением типа VALUE_TYPE как nvarchar2(2000)
  3. В теле пакета в теле процедуры get_value_type раскомментируйте строку с оператором return, возвращающим константу VALUE_TYPE_VARCHAR2
  4. В теле пакета в теле процедуры get_value_type закомментируйте строку с оператором return, возвращающим константу VALUE_TYPE_NVARCHAR2
  5. Перекомпилируйте спецификацию и тело пакета
  6. При необходимости, перекомпилируйте все объекты, которые зависят от пакета RTL_TYPES
*/

    /* Тип данных значений, получаемых/устанавливаемых функциями runtime ТЯ */
    subtype VALUE_TYPE is varchar2(4000);  -- Поддержка nvarchar2 отключена
    -- subtype VALUE_TYPE is nvarchar2(2000);   -- Поддержка nvarchar2 включена

    /* Функция возвращает тип данных значений, получаемых/устанавливаемых функциями runtime ТЯ ( VARCHAR2 / NVARCHAR2 )*/
    function get_value_type return varchar2;

end rtl_types;
/
show errors package rtl_types
