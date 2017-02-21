PROMPT NAV
CREATE OR REPLACE
PACKAGE NAV IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Nav1.sql $
 *  $Author: pistomin $
 *  $Revision: 128882 $
 *  $Date:: 2016-11-25 15:15:45 #$
 */
--------------------------------------------------------------
-- NAVIGATE - Модуль функций для работы навигатора
--            Copyright (c), 1996-1999, Financial Techologies Center Inc.
--------------------------------------------------------------
-- Переменные
--------------------------------------------------------------
   MAC  varchar2(12):='            ';
   IP   varchar2(15):='   .   .   .   ';
--------------------------------------------------------------
-- Функции
---------------------------------------------------------------
-- Получение версии
function get_version return varchar2;
---------------------------------------------------------------
-- Можно ли работать через Навигатор
function Is_Novo_Allowed return boolean;
---------------------------------------------------------------
-- Создание/удаление синонимов
PROCEDURE CreateSynonyms (mId IN VARCHAR2);
--------------------------------------------------------------
-- Сохраняем в переменных сетевой адрес клиента
---------------------------------------------------------------
FUNCTION SetNetAddresses (cMAC IN VARCHAR2, cIP IN VARCHAR2) RETURN CHAR;
---------------------------------------------------------------
-- Создание плана выполнения запроса
---------------------------------------------------------------
PROCEDURE Explain_Plan (Statement_Id IN VARCHAR2, txtSQL IN VARCHAR2);
---------------------------------------------------------------
-- Возвращает признак того, что пользователь привилегирован
---------------------------------------------------------------
FUNCTION Get_PrivUser (UserName IN VARCHAR2 DEFAULT NULL) RETURN CHAR DETERMINISTIC;
---------------------------------------------------------------
-- Возвращает признак того, что пользователь привилегирован
---------------------------------------------------------------
---------------------------------------------------------------
-- Возвращает признак того, что пароль является "боевым",
-- вход под ним запрещен.
---------------------------------------------------------------
FUNCTION Get_BattlePass RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Возвращает признак, что "Тип контролируется по реквизиту"
---------------------------------------------------------------
FUNCTION Attr_Access_Check (ClassId IN VARCHAR2, UserName IN VARCHAR2 DEFAULT NULL) RETURN CHAR DETERMINISTIC;
---------------------------------------------------------------
-- Возвращает доступность класса для показа в меню Навигатора
---------------------------------------------------------------
FUNCTION In_Menu (ClassId IN VARCHAR2, UserName IN VARCHAR2 DEFAULT NULL, FULL IN CHAR DEFAULT '1') RETURN CHAR DETERMINISTIC;
---------------------------------------------------------------
-- Возвращает доступность печати представления на принтер
---------------------------------------------------------------
FUNCTION Is_Print_View_Allowed (ClassId IN VARCHAR2, ViewId IN VARCHAR2, UserName IN VARCHAR2 DEFAULT NULL) RETURN CHAR DETERMINISTIC;
---------------------------------------------------------------
-- Возвращает доступность печати представления в файл
---------------------------------------------------------------
FUNCTION Is_Print_View_To_File_Allowed (ClassId IN VARCHAR2, ViewId IN VARCHAR2, UserName IN VARCHAR2 DEFAULT NULL) RETURN CHAR DETERMINISTIC;
--------------------------------------------------------------
-- Преобразование даты из внутреннего формата в стандартный
--------------------------------------------------------------
FUNCTION Date_Char(dDate IN DATE, Precision IN NUMBER DEFAULT NULL)
  RETURN VARCHAR2 DETERMINISTIC;
--------------------------------------------------------------
-- Преобразование числа из внутреннего формата в стандартный
--------------------------------------------------------------
FUNCTION Number_Char(nNumber IN NUMBER,
                     Precision IN NUMBER DEFAULT NULL)
 RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Разименовывает ссылку
---------------------------------------------------------------
FUNCTION Get_Reference_Value(ObjRef IN varchar2) RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Возвращает значение простого реквизита
-------------------------------------------------------------
-- FUNCTION Get_Value(ObjId IN VARCHAR2, AttrId IN VARCHAR2, Bc IN VARCHAR2,
--         Width IN NUMBER, Dec IN NUMBER, Complex IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;
---------------------------------------------------------------
-- Возвращает наименование состояни
---------------------------------------------------------------
FUNCTION Get_State_Name(StateId IN Varchar2)
         RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Получение уровня в иерархии классов
---------------------------------------------------------------
FUNCTION Class_Level(ClsId IN VARCHAR2) RETURN INTEGER DETERMINISTIC;
---------------------------------------------------------------
-- Проверка на принадлежность родителю
---------------------------------------------------------------
FUNCTION Is_Child(prn_id IN VARCHAR2, child_id IN VARCHAR2)
  RETURN CHAR DETERMINISTIC;
---------------------------------------------------------------
-- Проверка на заполненность Collection
---------------------------------------------------------------
FUNCTION Check_Collection(ColId IN NUMBER)
  RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Проверка на заполненность OLE-реквизита
---------------------------------------------------------------
FUNCTION Check_Ole(OleId IN NUMBER)
  RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Проверка на существования критериев
---------------------------------------------------------------
PROCEDURE Check_Criteria(ClsId IN Varchar2);
---------------------------------------------------------------
-- Возвращает текст View критери
---------------------------------------------------------------
FUNCTION Get_Vw_Crit(mId IN Varchar2) RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Журналирование представлений
-- p_action = VIEW | PRINT_VIEW
---------------------------------------------------------------
function log_view(p_crit in varchar2, p_action in varchar2 default 'VIEW') return number;
procedure log_view_par(p_id number, p_name varchar2, p_value varchar2);
---------------------------------------------------------------
-- Возвращает значения системных установок
---------------------------------------------------------------
FUNCTION Get_SysInfo(Value_Name IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Возвращает сетевое имя
---------------------------------------------------------------
FUNCTION Get_UserShortName RETURN VARCHAR2 DETERMINISTIC;
FUNCTION Get_UserName RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Возвращает свойства пользователя (Users.Properties)
---------------------------------------------------------------
FUNCTION Get_UserProp RETURN VARCHAR2 DETERMINISTIC;
---------------------------------------------------------------
-- Устанавливает ID реквизита типа OLE
---------------------------------------------------------------
FUNCTION Set_Ole_Id(ObjId IN varchar2, ClassId IN Varchar2, Qual IN VARCHAR2)
     RETURN number;
FUNCTION Del_Ole_Id(ObjId IN varchar2, ClassId IN Varchar2, Qual IN VARCHAR2)
     RETURN varchar2;
---------------------------------------------------------------
-- Работа с реквизитами типа OLE с kernel = true
---------------------------------------------------------------
function open_ole(obj_id in varchar2, class_id in varchar2, qual in varchar2,
                  obj_type out varchar2, will_write in number default 0) return number;
function get_ole_datab(ahandle in number, abuffer out raw,
                       aoffset in integer default null,
                       aamount in binary_integer default null) return binary_integer;
function get_ole_datac(ahandle in number, abuffer out varchar2,
                       aoffset in integer default null,
                       aamount in binary_integer default null) return binary_integer;
procedure set_ole_datab(ahandle in number, abuffer in raw,
                        aoffset in integer default null,
                        aamount in binary_integer default null);
procedure set_ole_datac(ahandle in number, abuffer in varchar2,
                        aoffset in integer default null,
                        aamount in binary_integer default null);
function get_blocator(ahandle in number) return blob;
function get_clocator(ahandle in number) return clob;
function get_flocator(ahandle in number) return bfile;
procedure close_ole(handle in number);
---------------------------------------------------------------
-- Работа с данными типа BLOB|CLOB в таблицах LONG_DATA, LRAW, ORSA_JOBS_OUT, LICENSE_DATA, ORSA_PAR_LOB
---------------------------------------------------------------
function open_lob(p_table in varchar2, p_id in varchar2, p_mode in number default 0) return number;
function open_lob(p_job number, p_pos number, p_out_type varchar2 default 'out', p_mode in number default 0) return number;
-- открытие  BLOB|CLOB в ORSA_PAR_LOB
function open_lob(p_job number, p_pos number, p_param varchar2, p_type varchar2, p_mode in number default 0) return number;
function get_lob_data(p_handle in number, p_data out raw, p_pos pls_integer default null,
                      p_size pls_integer default null) return pls_integer;
function get_lob_datac(p_handle in number, p_data out varchar2, p_pos pls_integer default null,
                      p_size pls_integer default null) return pls_integer;
function set_lob_data(p_handle in number, p_data in raw, p_pos pls_integer default null,
                      p_size pls_integer default null) return pls_integer;
function set_lob_datac(p_handle in number, p_data in varchar2, p_pos pls_integer default null,
                      p_size pls_integer default null) return pls_integer;
function clear_lob_data(p_handle number, p_size pls_integer default null) return pls_integer;
function close_lob(p_handle number, p_commit boolean default true) return number;
procedure find_sul(p_list in out nocopy  varchar2);
---------------------------------------------------------------
-- Работа с шаблонами печати представлений
---------------------------------------------------------------
procedure edit_criteria_print(criteria_id varchar2, name varchar2, header varchar2,
                              font_name varchar2, outfile varchar2, keys varchar2,
                              delimiter varchar2, quote varchar2, page varchar2);
---
procedure delete_criteria_print(criteria_id varchar2, name varchar2);
---
procedure edit_criteria_print_column(criteria_id varchar2, print_name varchar2,
                                     alias varchar2, position number, width number,
                                     oper varchar2 default null,
                                     quote varchar2 default null,
                                     align varchar2 default null);
---
procedure delete_criteria_print_column(criteria_id varchar2, print_name varchar2,
                                     alias varchar2 default null);
---------------------------------------------------------------
-- Работа с Электронным Документооборотом.
---------------------------------------------------------------
function get_attrs(p_edt_id varchar2) return varchar2;
---
procedure add_sign(p_edt_id varchar2, p_obj_id varchar2,
    p_block raw, p_sign raw, p_state_id varchar2 := null);
---
procedure check_sign(id number, code out number, key_id out varchar2, error out varchar2);
---
procedure log_edoc(p_obj_id varchar2, p_class_id varchar2,
    p_edt_id varchar2, p_code varchar2, p_text varchar2 := null);
---
procedure disable_as_sign;
---------------------------------------------------------------
-- Борьба с глюками
---------------------------------------------------------------
PROCEDURE Bug_Fix;
---------------------------------------------------------------
-- Переходник в FORMS_MGR: Если нет формы, то создает ее
---------------------------------------------------------------
procedure Frm_Touch(meth in varchar2);
---------------------------------------------------------------
-- Проверка интерфейсного пакета операции
---------------------------------------------------------------
function check_method_interface( p_method IN varchar2 ) return varchar2;
---------------------------------------------------------------
-- Получение ID операции для выполняемого интерфейсного пакета
---------------------------------------------------------------
function current_form_method_id return varchar2;
---------------------------------------------------------------
-- Получение ID операции по CLASS_ID, SHORT_NAME c учетом наследования
---------------------------------------------------------------
function get_method_id(p_class varchar2,p_short_name varchar2) return varchar2;
---------------------------------------------------------------
--  Курсоры
procedure Select_Cursor (CURSOR_NAME IN varchar2, P_CURSOR IN OUT nocopy constant.REPORT_CURSOR);
procedure Select_History(p_obj_id    varchar2,
                         p_class_id  varchar2,
                         p_qual      varchar2,
                         p_like_qual varchar2,
                         p_cursor in out nocopy constant.report_cursor);
---------------------------------------------------------------
--  Переходники
function value_ext(p_obj_id varchar2, p_xqual varchar2, p_meth_id varchar2 default null,p_class_id varchar2 default null) return varchar2;
function obj_name (p_obj_id varchar2, p_class_id varchar2 default null) return varchar2;
FUNCTION Address_Accessible (Address_ IN VARCHAR2, UserName_ IN VARCHAR2 DEFAULT NULL) RETURN CHAR DETERMINISTIC;
FUNCTION Object_Class (p_object_id IN varchar2, p_class varchar2) RETURN VarChar2 DETERMINISTIC;
function get_class ( p_object_id in out nocopy varchar2,
                     p_class varchar2 default NULL,
                     p_info  varchar2 default NULL
                   ) return varchar2;
function get_key  ( p_object_id IN varchar2,
                    p_class varchar2 default NULL
                  ) return varchar2;
procedure get_class_key ( p_object_id IN varchar2,
                          p_class in out varchar2,
                          p_key out number
                        );
function needs_collection_id(class_id_ varchar2,p_self varchar2 default '1') return varchar2 DETERMINISTIC;
pragma RESTRICT_REFERENCES (needs_collection_id, TRUST, WNDS, WNPS );
function get_client_script ( p_method IN varchar2 ) return varchar2 DETERMINISTIC;
pragma RESTRICT_REFERENCES ( get_client_script, WNDS, WNPS );
function get_client_script ( p_class IN varchar2, p_short_name varchar2) return varchar2;
function  extract_property(p_string   in varchar2,
                           p_property in varchar2 default NULL) return varchar2 deterministic;
pragma RESTRICT_REFERENCES ( extract_property, WNDS, WNPS );
procedure put_property(p_string in out nocopy varchar2,
                   p_property  in varchar2 default null,
                   p_value  in varchar2 default null);
pragma RESTRICT_REFERENCES ( put_property, WNDS, WNPS );
-- change state with logical locks
function change_state_request (
                         p_object_id   varchar2,
                         p_new_state   varchar2,
                         p_method_name varchar2,
                         p_class_id    varchar2,
                         p_obj_locks   varchar2,
                         p_info        varchar2
                        ) return varchar2;
---------------------------------------------------------------
function Check_Error_Message(p_message in out nocopy varchar2) return varchar2 DETERMINISTIC;
  PRAGMA RESTRICT_REFERENCES (Check_Error_Message, WNDS, WNPS);
function qual2names(aclass_id in varchar2, aqual in varchar2) return varchar2 DETERMINISTIC;
  PRAGMA RESTRICT_REFERENCES (qual2names, WNDS, WNPS);
---------------------------------------------------------------
procedure SetModule (p_module IN varchar2, p_action varchar2);
---------------------------------------------------------------
-- Отчеты ORSA
---------------------------------------------------------------
procedure Check_Report_Rights(p_username varchar2);
procedure Check_Report_User(p_username  in out nocopy varchar2,
                            p_os_user   varchar2, p_os_domain varchar2);
procedure Create_Report(p_job in out nocopy number, p_pos in out nocopy number,
                        p_username varchar2, p_os_user   varchar2, p_os_domain varchar2,
                        p_class_id varchar2, p_method_id varchar2, p_params    varchar2,
                        p_rpt_name varchar2, p_out_name  varchar2, p_props     varchar2,
                        p_rpt_drv  varchar2, p_trace_opt varchar2, p_schedule  date,
                        p_priority number );
procedure Create_Report_UAdmin(p_job       in out nocopy number
                              ,p_username  varchar2
                              ,p_params    varchar2
                              ,p_rpt_name  varchar2
                              ,p_out_name  varchar2
                              ,p_props     varchar2
                              ,p_rpt_drv   varchar2
                              ,p_trace_opt varchar2
                              ,p_schedule  date
                              ,p_priority  number);
procedure Create_Report_PDAdmin(p_job       in out nocopy number
                               ,p_username  varchar2
                               ,p_params    varchar2
                               ,p_rpt_name  varchar2
                               ,p_out_name  varchar2
                               ,p_props     varchar2
                               ,p_rpt_drv   varchar2
                               ,p_trace_opt varchar2
                               ,p_schedule  date
                               ,p_priority  number);
procedure Delete_Report(p_username varchar2, p_job number, p_pos number);
procedure Rerun_Report (p_username varchar2, p_job number, p_pos number);
procedure Cancel_Report(p_username varchar2, p_job number, p_pos number);
function Lock_Report(p_username varchar2, p_job number, p_pos number) return number;
---------------------------------------------------------------
--
---------------------------------------------------------------
subtype NETWORK_NODE_TYPE is pls_integer;

NODE_TYPE_CLIENT constant NETWORK_NODE_TYPE := 0;
NODE_TYPE_AS constant NETWORK_NODE_TYPE := 1;
NODE_TYPE_TS constant NETWORK_NODE_TYPE := 2;

procedure network_register_node(p_nodeType pls_integer, p_name varchar2, p_ip varchar2,
                                p_osUser   varchar2, p_module varchar2 default null);
---------------------------------------------------------------
procedure write_action(p_meth varchar2, p_action varchar2, p_param1 varchar2, p_value1 varchar2,
p_param2 varchar2 default null, p_value2 varchar2 default null,
p_param3 varchar2 default null, p_value3 varchar2 default null,
p_param4 varchar2 default null, p_value4 varchar2 default null,
p_param5 varchar2 default null, p_value5 varchar2 default null);
---------------------------------------------------------------
-- Прагмы
---------------------------------------------------------------
  PRAGMA RESTRICT_REFERENCES (Get_PrivUser, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Get_UserShortName, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Get_UserName, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Get_UserProp, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (In_Menu, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Date_Char, RNDS, RNPS, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Number_Char, RNDS, RNPS, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Get_Reference_Value, WNDS);
--  PRAGMA RESTRICT_REFERENCES (Get_Value, WNDS, WNPS);
--  PRAGMA RESTRICT_REFERENCES (Get_Vw_Crit, WNDS, WNPS); -- commented for Oracle 12c
  PRAGMA RESTRICT_REFERENCES (Class_Level, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Is_Child, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Get_State_Name, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Check_Collection, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Attr_Access_Check, WNDS, WNPS);
  PRAGMA RESTRICT_REFERENCES (Address_Accessible, WNDS, WNPS);
END;
/
sho err
