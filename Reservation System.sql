create table TrainList(
tnumber varchar(5) not null,
tname varchar(20),
tsource varchar(20),
tdestination varchar(20),
ac_fair decimal(5,2),
general_fair decimal(5,2),
Monday char(1),
Tuesday char(1),
Wednesday char(1),
Thursday char(1),
Friday char(1),
Saturday char(1),
Sunday char(1),
Constraint TRAINLIST_PK Primary Key(tnumber));

create table train_status(
tnumber varchar(5),
train_date Date,
ac_seats number(4),
general_seats number(4),
ac_seats_booked number(4),
general_seats_booked number(4),
Constraint STATUS_FK Foreign Key (tnumber) references trainlist(tnumber));

create table passenger(
p_id varchar(5),
p_name varchar(20),
p_address varchar(40),
p_dob Date,
gender varchar(2),
Constraint PASSENGER_PK Primary Key(p_id));

create table reservation(
ticket_id number(5),
tnumber varchar(5),
booking_date Date,
p_name varchar(20),
p_age varchar(20),
p_sex varchar(2),
p_address varchar(40),
status varchar(15)
check(status in ('Confirmed','Waiting')),
t_category varchar(10),
Constraint RESERVATION_PK Primary Key(ticket_id),
Constraint RESERVATION_FK Foreign Key(tnumber) references trainlist(tnumber));

create table cancellation(
ticket_id number(5),
tnumber varchar(5),
cancellation_date Date,
p_name varchar(20),
p_age varchar(20),
p_sex varchar(2),
p_address varchar(40),
status varchar(15),
t_category varchar(10),
Constraint CANCELLATION_PK Primary Key(ticket_id),
Constraint CANCELLATION_FK Foreign Key(tnumber) references trainlist(tnumber));

create table transaction_audit(
ticket_id number(5),
tnumber varchar(5),
booking_date Date,
p_name varchar(20),
p_age varchar(20),
p_sex varchar(2),
p_address varchar(40),
status varchar(15),
t_category varchar(10),
Transaction_status varchar(25));

create sequence ticket_seq
start with 1101
increment by 1;

create or replace procedure booking(pid passenger.p_id%type, tnum trainlist.tnumber%type, tdate train_status.train_date%type, tcategory reservation.t_category%type)
as
begin
declare
    ac_s    train_status.ac_seats%type;
    g_s     train_status.general_seats%type;
    ac_s_b  train_status.ac_seats_booked%type;
    g_s_b   train_status.general_seats_booked%type;
    pname   passenger.p_name%type;
    paddr   passenger.p_address%type;
    p_gen   passenger.gender%type;
    p_ag    reservation.p_age%type;
    t_id    reservation.ticket_id%type;
    trains  number := 0;
    in_wait number := 0;
    ttest   number := 0;
    CURSOR  categories is Select ac_seats, general_seats, ac_seats_booked, general_seats_booked, count(train_date) from train_status
            where tnumber = tnum and train_date = tdate
            group by ac_seats, general_seats, ac_seats_booked, general_seats_booked;
    CURSOR  passenger_details is Select p_name, p_address, TRUNC(MONTHS_BETWEEN(SYSDATE,p_dob)/12), gender from passenger where p_id = pid;
    CURSOR  in_waiting is Select count(ticket_id) from reservation where status = 'Waiting' and booking_date = tdate and tnumber = tnum and t_category = tcategory group by ticket_id;
    begin
    open categories;
        fetch categories into ac_s, g_s, ac_s_b, g_s_b, trains;
    close categories;
    if trains > 0
        then
            if tcategory = 'AC'
                then
                    open in_waiting;
                        LOOP
                            fetch in_waiting into ttest;
                            in_wait := in_wait + 1;
                            exit when in_waiting%NotFOUND;
                        END LOOP;
                    close in_waiting;
                    if ac_s_b < ac_s
                        then
                            t_id := ticket_seq.nextval;
                            open passenger_details;
                                fetch passenger_details into pname, paddr, p_ag, p_gen;
                            close passenger_details;
                            Insert into reservation values(t_id, tnum, tdate,pname,p_ag,p_gen,paddr,'Confirmed',tcategory);
                            Update train_status
                            set ac_seats_booked = ac_seats_booked + 1
                            where tnumber = tnum and train_date = tdate;
                            dbms_output.put_line('Ticket ID: ' || t_id);
                            dbms_output.put_line('Your Booking has been done!!!');
                    elsif in_wait <= 2
                        then
                            t_id := ticket_seq.nextval;
                            open passenger_details;
                                fetch passenger_details into pname, paddr, p_ag, p_gen;
                            close passenger_details;
                            Insert into reservation values(t_id, tnum, tdate,pname,p_ag,p_gen,paddr,'Waiting',tcategory);
                            dbms_output.put_line('Ticket ID: ' || t_id);
                            dbms_output.put_line('Your Booking has been done under Waiting Status!!!');
                    else
                        dbms_output.put_line('Unfortunately, All Seats are booked, Booking cannot be done!!!');
                            end if;
            elsif tcategory = 'General'
                then
                    open in_waiting;
                        LOOP
                            fetch in_waiting into ttest;
                            in_wait := in_wait + 1;
                            exit when in_waiting%NotFOUND;
                        END LOOP;
                    close in_waiting;
                    if g_s_b < g_s
                        then
                            t_id := ticket_seq.nextval;
                            open passenger_details;
                                fetch passenger_details into pname, paddr, p_ag, p_gen;
                            close passenger_details;
                            Insert into reservation values(t_id, tnum, tdate,pname,p_ag,p_gen,paddr,'Confirmed',tcategory);
                            Update train_status
                            set general_seats_booked = general_seats_booked + 1
                            where tnumber = tnum and train_date = tdate;
                            dbms_output.put_line('Ticket ID: ' || t_id);
                            dbms_output.put_line('Your Booking has been done!!!');
                    elsif in_wait <= 2
                        then
                            t_id := ticket_seq.nextval;
                            open passenger_details;
                                fetch passenger_details into pname, paddr, p_ag, p_gen;
                            close passenger_details;
                            Insert into reservation values(t_id, tnum, tdate,pname,p_ag,p_gen,paddr,'Waiting',tcategory);
                            dbms_output.put_line('Ticket ID: ' || t_id);
                            dbms_output.put_line('Your Booking has been done under Waiting Status!!!');
                    else
                        dbms_output.put_line('Unfortunately, All Seats are booked, Booking cannot be done!!!');
                    end if;
            end if;
    else
        dbms_output.put_line('The Train Information does not exist');
    end if;
    end;
end;
/

create or replace procedure cancel_booking(t_id reservation.ticket_id%type)
as
begin
declare
    count_train     number := 0;
    count_waiting   number := 0;
    tick_id         reservation.ticket_id%type;
    tnum            reservation.tnumber%type;
    p_n             reservation.p_name%type;
    p_ag            reservation.p_age%type;
    p_s             reservation.p_sex%type;
    p_addr          reservation.p_address%type;
    p_stat          reservation.status%type;
    tdate           reservation.booking_date%type;
    t_cat           reservation.t_category%type;
    CURSOR          search_reserv is Select count(ticket_id) from reservation where ticket_id = t_id group by ticket_id;
    CURSOR          get_record is Select tnumber, p_name, p_age, p_sex, p_address, status, t_category, booking_date from reservation where ticket_id = t_id;
    CURSOR          waiting is Select ticket_id, count(ticket_id) from reservation where status = 'Waiting' and tnumber = (select tnumber from reservation where ticket_id = t_id) group by ticket_id;
    begin
        open search_reserv;
            fetch search_reserv into count_train;
        close search_reserv;
        if count_train > 0
            then
                open get_record;
                    fetch get_record into tnum, p_n, p_ag, p_s, p_addr, p_stat, t_cat, tdate;
                close get_record;
                if p_stat = 'Confirmed'
                    then
                        open waiting;
                            fetch waiting into tick_id, count_waiting;
                        close waiting;
                        if count_waiting > 0
                             then
                                update reservation
                                set status = 'Confirmed'
                                where ticket_id = tick_id;
                        else
                            if t_cat = 'General'
                                then
                                    Update train_status
                                    set general_seats_booked = general_seats_booked - 1
                                    where tnumber = tnum and train_date = tdate;
                            elsif t_cat = 'AC'
                                then
                                    Update train_status
                                    set ac_seats_booked = ac_seats_booked - 1
                                    where tnumber = tnum and train_date = tdate;
                            end if;
                        end if;
                end if;
                Delete from reservation
                where ticket_id = t_id;
                dbms_output.put_line('Booking for Ticket ID: ' || t_id || ' has been cancelled');
                Insert into cancellation values(t_id, tnum, to_date(sysdate()), p_n, p_ag, p_s, p_addr, p_stat, t_cat);
        else
            dbms_output.put_line('No Reservation for Ticket ID: ' || t_id || ' found.');
        end if;
    end;
end;
/

create or replace trigger updating_audit
before insert or delete on reservation
for each row
begin
    if inserting
        then
            insert into transaction_audit values(:new.ticket_id, :new.tnumber, :new.booking_date, :new.p_name, :new.p_age,
                                    :new.p_sex, :new.p_address, :new.status, :new.t_category, 'Reservation');
    elsif deleting
        then
            insert into transaction_audit values(:old.ticket_id, :old.tnumber, :old.booking_date, :old.p_name, :old.p_age,
                                    :old.p_sex, :old.p_address, :old.status, :old.t_category, 'Cancellation');
    end if;
end;
/

insert into trainlist values('A001','Toshi Express','Kamloops','Prince George','23.4','12.3','Y', 'N', 'N','Y','N','N','Y');
insert into trainlist values('A003','Macro Passenger','Vancouver','Calagary','32.2','19.2','N', 'Y', 'N','Y','Y','N','Y');
insert into trainlist values('BC08','Lotus Express','Burnaby','Richmond','15.3','10.1','Y', 'Y', 'N','Y','N','Y','Y');
insert into trainlist values('AD05','Moxie Xpress','Abbotsford','Edmonton','31.2','23.4','N', 'Y', 'N','Y','N','N','Y');
insert into trainlist values('AD02','Crescent Passenger','Smithers','Castlegar','38.2','23.4','N', 'Y', 'N','Y','Y','Y','N');

select * from trainlist;

insert into train_status values('A001', to_date('29-03-2021','DD-MM-YYYY'), 5, 5, 0, 0);
insert into train_status values('BC08', to_date('10-04-2021','DD-MM-YYYY'), 5, 5, 0, 0);
insert into train_status values('A003', to_date('31-03-2021','DD-MM-YYYY'), 5, 5, 0, 0);
insert into train_status values('AD05', to_date('15-04-2021','DD-MM-YYYY'), 5, 5, 0, 0);
insert into train_status values('AD02', to_date('24-03-2021','DD-MM-YYYY'), 5, 5, 0, 0);
insert into train_status values('BC08', to_date('27-03-2021','DD-MM-YYYY'), 5, 5, 0, 0);

select * from train_status;

insert into passenger values('P012', 'John Smith', '231 Squash St., Abbotsford, V2S 1F3, BC', to_date('12-05-1989','DD-MM-YYYY'),'M');
insert into passenger values('P024', 'Marry Poppins', '12 Tremble St., Edmonton, G2S 2A4, AB', to_date('21-09-1975','DD-MM-YYYY'),'F');
insert into passenger values('P003', 'Lorrie Griener', '2-542 Cargo Ave., Kelowna, V2T 4K2, BC', to_date('09-11-1994','DD-MM-YYYY'),'F');

select * from passenger;

set serveroutput on

exec booking('P012','A001', to_date('29-03-2021','DD-MM-YYYY'),'General');
exec booking('P024','AD05', to_date('15-04-2021','DD-MM-YYYY'),'AC');
exec booking('P024','AD05', to_date('15-04-2022','DD-MM-YYYY'),'AC');
exec cancel_booking(1137);
