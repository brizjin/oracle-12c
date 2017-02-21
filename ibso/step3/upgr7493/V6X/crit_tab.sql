alter table criteria add nested_qual varchar2(700);

alter table criteria_columns add ref_qual varchar2(700);
alter table criteria_columns add ref_class_id varchar2(16);
alter table criteria_columns add ref_crit_id varchar2(16);
alter table criteria_columns add ref_condition varchar2(2000);

alter table criteria_columns add filter_required varchar2(1);
alter table criteria_columns add filter_condition varchar2(10);
alter table criteria_columns add hint varchar2(2000);
alter table criteria_columns add hint_priority number;

alter table criteria_columns add tool_tip varchar2(200);

alter trigger CRITERIA_COLUMNS_CHANGES disable;

update criteria_columns cc set ref_crit_id=null
where ref_crit_id is not null and not exists
(select 1 from criteria c where c.id=cc.ref_crit_id);

update criteria_columns cc set ref_class_id=null
where ref_class_id is not null and not exists
(select 1 from classes c where c.id=cc.ref_class_id);

alter table criteria_columns add constraint fk_crit_columns_r_class_id
  foreign key(ref_class_id) referencing classes(id)  on delete set null;
alter table criteria_columns add constraint fk_crit_columns_r_crit_id
  foreign key(ref_crit_id)  referencing criteria(id) on delete set null;

alter trigger CRITERIA_COLUMNS_CHANGES enable;

set term off
/*
1) filter_required varchar2(1) - '1', '0'. Значение колонки обязано присутствовать в фильтре.
При этом, если у нескольких колонок этот признак '1', то обязана присутствовать любая из них.
Если есть колонки с '1', то снять фильтр нельзя.
2) filter_condition varchar2(10) - 'eq', 'ne', 'lt', 'gt', 'like' и т.д. Операция по
умолчанию в комбобоксе на экране задания условия на эту колонку.
3) hint varchar2(2000) - если колонка задана в фильтре, то добавлять этот hint к запросу.
4) hint_priority number - если у всех колонок, заданных в фильтре, hint_priority >= 0,
то это номер хинта в запросе. Если один или несколько hint_priority < 0, то используется
тот, у которого abs(hint_priority) максимальный.

5) tool_tip varchar2(200) - всплывающая подсказка к колонке.

6) ref_class_id varchar2(16) и ref_crit_id varchar2(16) - будут определять тип и представление,
куда следует проваливаться (ссылаемое представление).
7) ref_condition varchar2(2000), которая в зависимости от ref_type будет содержать
либо просто алиас для ссылаемого представления, либо произвольное логическое условие.
*/
set term on