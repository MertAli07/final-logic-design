`timescale 1ms / 100ns

module siganfu_machine_gun (
	input sysclk,
	input reboot,
	input target_locked,
	input is_enemy,
	input fire_command,
	input firing_mode, // 0 single, 1 auto
	input overheat_sensor,
	output reg[2:0] current_state,
	output reg criticality_alert,
	output reg fire_trigger
);
reg[2:0] nextstate;
parameter idle=3'b000;
parameter shoot_single=3'b001;
parameter shoot_auto=3'b010;
parameter reload=3'b011;
parameter overheat=3'b100;
parameter downfall=3'b101;

assign firing_condition = is_enemy && target_locked && fire_command; //all of them must be HIGH to shoot

integer bullet = 25;
integer magazine = 3;
integer shot = 0; //checks if shoot_single has already been shot

always @(posedge sysclk or posedge reboot) // always block to update state
if (reboot)
 current_state <= idle;
else
 current_state <= nextstate;
 
 
 always @(current_state or firing_condition or reboot or firing_mode or overheat_sensor)
 begin
    case(current_state)
        idle:
        begin
             if(firing_condition && firing_mode == 0)
             begin
                 fire_trigger = 0;
                 nextstate = shoot_single;
             end
             else if(firing_condition && firing_mode == 1)
             begin
                 fire_trigger = 0;
                 nextstate = shoot_auto;
             end
             else
             begin
               fire_trigger=0;
               nextstate = idle;
             end
         end
        shoot_single:
            if(overheat_sensor)
            begin
                shot = 0;
                nextstate = overheat;
            end
            else if(bullet > 0)
            begin
                if(shot == 0)
                begin
                    fire_trigger = 1;
                    #5;
                    fire_trigger = 0;
                    bullet = bullet - 1;
                    shot = 1;
                end
                if(fire_command == 0)
                begin
                    shot = 0;
                    nextstate=idle;
                end
            else if(bullet == 0 && magazine > 0)
            begin
                shot = 0;
                nextstate=reload;
            end
            else if(bullet == 0 && magazine == 0)
            begin
                shot = 0;
                nextstate = downfall;
            end
            end
         shoot_auto:
         begin
           while((fire_command == 1) && (bullet>0) && (overheat_sensor == 0) && (firing_condition == 1))
               begin
                   fire_trigger = 1;
                   bullet = bullet - 1;
                   #5;
                   fire_trigger = 0;
                   #5;
               end
            if(overheat_sensor)
                nextstate = overheat;
            else if(firing_condition == 0)
                nextstate=idle;
            else if(bullet == 0)
            begin
                if(magazine > 0)
                    nextstate=reload;
                else
                    nextstate=downfall;
            end
        end
        reload:
        begin
            if(magazine > 0)
            begin
                magazine = magazine - 1;
                bullet = 25;
                #50;
            end
            else if(magazine < 0)
                nextstate = downfall;
            if(firing_condition)
                begin
                    if(firing_mode == 1)
                        nextstate = shoot_auto;
                    else
                        nextstate = shoot_single;
                end
             else
                nextstate = idle;
        end
        overheat:
        begin
            #100;
            if(firing_condition)
            begin
                if(bullet == 0 && magazine < 0)
                    nextstate = downfall;
                else if(bullet == 0 && magazine >= 0)
                    nextstate = reload;
                else if(firing_mode == 0)
                    nextstate=shoot_single;
                else
                    nextstate = shoot_auto;
            end
            else if(bullet == 0 && magazine < 0)
                nextstate = downfall;
            else if(bullet == 0 && magazine >= 0)
                nextstate = reload;
            else
                nextstate=idle;
        end
        downfall:
        begin
            if(reboot == 1)
            begin
                bullet = 25;
                magazine = 3;
                nextstate = idle;
            end
        end
    endcase
 end
 
 always @(magazine) //always block to check the criticality alert
 begin
    if(magazine == 0)
        criticality_alert = 1;
    else
        criticality_alert = 0;
 end

endmodule
