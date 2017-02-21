prompt SC_MGR
create or replace package sc_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/sc_mgr1.sql $
 *  $Author: kuvardin $
 *  $Revision: 44167 $
 *  $Date:: 2014-04-04 09:13:18 #$
 */

-- Доступность функционала МТ
function enabled return boolean;

-- Перейти в режим записи теста
-- Поместить информацию о сессии в таблицу SC_SESSIONS:
-- В колонке mode_ses информация о режиме работы сессии:
-- REC - запись теста
-- PLAY - воспроизведение теста
-- RESTORE - откат изменений
-- В колонке info1 - ID сценария, в info2 - ID сеанса
-- если в sc_sessions нет информации о текущей сессии, то эта информация будет добавлена с режимом mode_ses='PLAY'
procedure start_rec(p_commit_mode boolean default false, p_do_rollback boolean default false, p_info1 varchar2, p_info2 varchar2);

-- Выключить режим записи теста
procedure stop_rec;
-- Приостановить режим записи теста
procedure pause_rec;
-- Продолжить запись теста
procedure resume_rec;

-- Перейти в режим воспроизведения теста
-- если в sc_sessions нет информации о текущей сессии, то эта информация будет добавлена с режимом mode_ses='PLAY'
procedure start_play(p_commit_mode boolean default false, p_do_rollback boolean default false, p_info1 varchar2, p_info2 varchar2);

-- Выключить режим воспроизведения теста
procedure stop_play;

-- Включить защиту экземпляров
procedure start_protect;
-- Выключить защиту экземпляров
procedure stop_protect;
-- Возвращает признак, что включен режим защиты экземпляров
function protected return boolean;
-- Установка в глобальном контексте по переданному в массиве p_arr списку ID защищаемых экземпляров
-- признака защиты экземпляра p_set(1-защищен от изменений, 0-снята защита )
procedure set_ids(p_arr "CONSTANT".MEMO_TABLE, p_set varchar2 default '1');

-- Включить журналирование работы с файлами
procedure start_fio_logging;
-- Выключить журналирование работы с файлами
procedure stop_fio_logging;
-- Приостановить журналирование работы с файлами
procedure pause_fio_logging;
-- Продолжить журналирование работы с файлами
procedure resume_fio_logging;

-- Перейти в режим восстановления данных
-- если в sc_sessions нет информации о теккущей сессии, то эта информация будет добавлена с режимом mode_ses='RESTORE'
procedure start_restore(p_info1 varchar2, p_info2 varchar2);

-- Приостановить журналирование изменений в БД
procedure pause_repl;
-- Продолжить журналирование изменений в БД
procedure resume_repl;

-- Возвращает признак, что в текущей сессии включен режим записи теста
function is_recording return boolean;
-- Возвращает признак, что в текущей сессии включен режим воспроизведения теста
function is_playing return boolean;
-- Возвращает признак, что в текущей сессии ведется работа с тестами
function is_testing return boolean;
-- Возвращает признак, что в текущей сессии ведется журналирование работы с файлами
function is_fio_logging return boolean;


-- Создание глобального контекста для МТ (используется только при установке МТ)
procedure install;


-- Проверка наличия сессий, в которых производится запись или воспроизведение тестов
-- При p_refresh==true очищается информация о незарегистрированных сессиях
function rec_play (p_refresh boolean) return boolean;
-- Очстка информации о незарегистрированных сессиях
procedure refresh_sessions;
-- Удаление информации о текущей сессии из таблицы sc_sessions
-- Момент удаления сессии из sc_sessions не совпадает с выключением режима записи и воспроизведения
-- т.к. существуют различные служебные действия уже после выключения режима
procedure delete_session;

-- Журналирование действий пользователя при записи теста
procedure write_log(mid varchar2, procname varchar2, aParams "CONSTANT".REFSTRING_TABLE, aValues "CONSTANT".STRING_TABLE,p_force boolean default false,
                    p_ext_logging boolean default false, p_t timestamp default null);
procedure write_log(mid varchar2, procname varchar2,
                    Param1 varchar2, Value1 varchar2,
                    Param2 varchar2 default null, Value2 varchar2  default null,
                    Param3 varchar2 default null, Value3 varchar2  default null,
                    Param4 varchar2 default null, Value4 varchar2  default null,
                    Param5 varchar2 default null, Value5 varchar2  default null,
                    p_force boolean default false, p_ext_logging boolean default false, p_t timestamp default null);

-- Дополнительное журналирование признака совпадения переданного значения в действии SET при записи теста
procedure add_log(aParams "CONSTANT".REFSTRING_TABLE, aValues "CONSTANT".STRING_TABLE);
procedure add_log(  Param1 varchar2, Value1 varchar2,
                    Param2 varchar2 default null, Value2 varchar2  default null,
                    Param3 varchar2 default null, Value3 varchar2  default null,
                    Param4 varchar2 default null, Value4 varchar2  default null,
                    Param5 varchar2 default null, Value5 varchar2  default null);
-- Сохранение информации об идентификаторах проинициализированных коллекций при записи теста
procedure write_coll(p_coll varchar2, p_class varchar2, p_value varchar2);

-- Функции для генерации сценария (дублириование функционала method_mgr)
function idx_by_qual(p_meth_id varchar2, p_qual varchar2, p_type varchar2 default null) return pls_integer;
function qual_by_var(p_meth_id varchar2, p_var varchar2) return varchar2;
procedure get_param(p_meth_id varchar2, p_action varchar2, p_parname varchar2,p_value varchar2,
                    aValues out "CONSTANT".MEMO_TABLE,
                    aTypes  out "CONSTANT".MEMO_TABLE,
                    aQuals  out "CONSTANT".MEMO_TABLE,
                    aIdx out "CONSTANT".INTEGER_TABLE);
procedure get_grid_param(p_meth_id varchar2, p_ind pls_integer, p_value in out NOCOPY varchar2,
                    p_command out varchar2,
                    aNames out "CONSTANT".MEMO_TABLE,
                    aValues out "CONSTANT".MEMO_TABLE);

-- Получение количества профилируемых строк в пакете операции
function get_num_lines(p_class varchar2, p_short_name varchar2) return pls_integer;

-- Функции для журналирования работы с файлами
procedure log_open_file (handle pls_integer, path varchar2, open_mode varchar2);
procedure log_close_file (handle pls_integer);
function  log_file_name(p_name varchar2, p_on_client varchar2) return varchar;
procedure set_name(p_on_client varchar2, p_name varchar2);
procedure clear_names;
procedure update_sessions(p_mode_ses varchar2,p_set boolean,p_info1 varchar2,p_info2 varchar2);

-- Функции для проверки возможности запуска теста, если уже запущен другой тест
procedure clear_test_information(p_info1 varchar2, p_mode_ses varchar2 DEFAULT NULL);

-- Функции для очистки следов сессий в случае ошибки при воспроизведении теста или после непредвиденных ошибок при воспроизведении теста(Пр.: падения экземпляра Oracle)
procedure deleteSession(p_sid number);
end SC_MGR;
/
show err

