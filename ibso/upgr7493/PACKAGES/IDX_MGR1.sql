prompt INDEX_MGR
CREATE OR REPLACE Package INDEX_MGR IS
  /*
  *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/IDX_MGR1.sql $
  *  $Author: vzhukov $
  *  $Revision: 94127 $
  *  $Date:: 2016-02-15 16#$
  */
  -- Регистрация первичного ключа
  PROCEDURE Register_Primary_Key(ClassId IN Varchar2);
  -- Создание индекса
  FUNCTION Create_Index(p_Name         IN varchar2,
                        p_rebuild      IN boolean default false,
                        p_ratio        IN number default 1,
                        p_tspacei      IN varchar2 default null,
                        p_ini_trans    IN number default null,
                        p_max_trans    IN number default null,
                        p_pct_free     IN number default null,
                        p_init_extent  IN number default null,
                        p_next_extent  IN number default null,
                        p_min_extents  IN number default null,
                        p_max_extents  IN number default null,
                        p_pct_increase IN number default null,
                        p_free_lists   IN number default null,
                        p_free_groups  IN number default null,
                        p_degree       IN number default null,
                        p_part_tspace  IN varchar2 default null,
                        p_position     pls_integer default null,
                        p_reverse      boolean default false,
                        p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                        ) RETURN VARCHAR2;
  -- Удаление индекса
  PROCEDURE Delete_Index(IndexName  IN varchar2,
                         p_position pls_integer default null);
  -- Заполнение таблицы индексов на основании реальных данных
  procedure Retrofit(p_class_id   in varchar2 default null,
                     p_index_name in varchar2 default null);
  -- Построение индексов
  procedure Create_Indexes(p_class_id   in varchar2 default null,
                           p_rebuild    in boolean default false,
                           p_pipe       in varchar2 default null,
                           p_start      in varchar2 default null,
                           p_ratio      in number default 1,
                           p_tspacei    in varchar2 default null,
                           p_parttspace varchar2 default null,
                           p_position   pls_integer default null,
                           p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                           );
END; -- Package spec
/
sho err
