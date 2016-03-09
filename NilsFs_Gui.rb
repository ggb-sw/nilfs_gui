#!/usr/bin/ruby
#
# Gui for NilsFS
#
# NilsFs_Gui.rb
#
# Author: George G. Bolgar
#
# This software provides a GUI that allows the users to easily create 
# or remove snapshots from a NILFS filesystem, and to mount those 
# snapshots as a read-only file system.
#
# Dependencies:
#         Ruby/TK
#         gksu
#         NILFS filesystem (only mounted drives will be recognised)
#
# Copyright: 2016-03-08
#
# Copyright is retained by author.
#
# Permission is granted for free distribution and use of this software 
# in unmodified form.
#
# No permission is granted for the sale of this software or for its
# distribution for profit.


require 'tk'


def GetDevices
    devices = []
    `mount -l -t nilfs2`.split("\n").reverse.each do |l|
        mat = l.match(/^\/(.*)\s+on\s+\/(.*)\s+type\s+nilfs2\s+/)
        unless(mat == nil)
            dev = '/' + mat[1]
            devices.push dev unless devices.include? dev
        end
    end
    return devices
end

class MountList < TkLabelFrame
    attr_writer :Selected, :Deselected
    attr_reader :Selection

    def ClearList
        while @list.size > 0
            @list.delete 0
        end
        @Selection = nil
        @Devices = []
        @Deselected.call unless @Deselected == nil
    end
    
    def Refresh
        self.ClearList
        @Devices = GetDevices()
        `mount -l -t nilfs2`.split("\n").reverse.each do |l|
            mat = l.match(/^\/(.*)\s+on\s+\/(.*)\s+type\s+nilfs2\s+\(.*\bcp=(\d+)\b.*\)\s*$/)
            next if mat == nil
            next unless mat.length == 4
            dev = '/' + mat[1]
            mnt = '/' + mat[2]
            cp = mat[3]
            ll = sprintf("%-18d %-30s %s", cp, mnt, dev)
            @list.insert 0,ll
        end
    end

    def GetSelection
        l = @list.get @list.curselection
        lx = l.split(' ')
        @Selection = { 'cp'=>lx[0], 'mount'=>lx[1] }
        @Selected.call unless @Selected == nil
    end
    
    def initialize root
        super root
        relief 'sunken'
        borderwidth 5
        background "grey"
        padx 2
        pady 2
        text 'Mounts'
        height -1
        pack('side' => 'top', :expand=>1, :fill=>'x')
        TkLabel.new(self) do
            text 'Checkpoint     Mount Point                    Device'
            anchor 'w'
            pack(:side => 'top',:fill => 'x', :expand=>1)
        end
        @list = TkListbox.new(self) do
            height -1
            selectmode 'single'
            pack(:side => 'top',:fill => 'x', :expand=>1)
        end
        @list.bind('ButtonRelease-1') { self.GetSelection }
        self.Refresh
    end
end


class CheckpointList < TkLabelFrame
    attr_writer :Selected, :Deselected
    attr_reader :Selection
    
    def ClearList
        while @list.size > 0
            @list.delete 0
        end
        @Selection = nil
        @Deselected.call unless @Deselected == nil
    end
    
    def Refresh
        self.ClearList
        @Devices = GetDevices()
        return if @Devices == nil
        @Devices.each do |dev|
            `lscp #{@Type} -b -r "#{dev}"`.split("\n").reverse.each do |l|
                next unless l =~ /\d/
                li = l.split(' ')
                cp = li[0].to_i
                dat = li[1]
                tim = li[2]
                t = li[3]
                next if t == 'ss' && @Type != '-s'
                ll = sprintf("%-10s %-8s  %15d       %s", dat, tim, cp, dev)
                @list.insert 0,ll
            end
        end
        @list.height = @list.size < 12 ? -1 : 12
    end
    
    def GetSelection
        x = @list.curselection
        l = @list.get x
        lx = l.split(' ')
        @Selection = { 'cp'=>lx[2], 'mount'=>lx[3] }
        @Selected.call unless @Selected == nil
    end
    
    def initialize root, type
        super root
        @Type = type
        relief 'sunken'
        borderwidth 5
        background "grey"
        padx 2
        pady 2
        text type == '-s' ? 'Snapshots  ' : 'Checkpoints'
        pack('side' => 'top', :expand=>1, :fill=>'x')
        t = type == '-s' ? 'Snapshot  ' : 'Checkpoint'
        TkLabel.new(self) do
            text "            Date                  Checkpoint      Device"
            anchor 'w'
            pack(:side => 'top',:fill => 'x', :expand=>1)
        end
        @list = TkListbox.new(self) do
            setgrid 1
            height 12
            selectmode 'single'
            pack(:side => 'top',:fill => 'x', :expand=>1)
        end
        @list.bind('ButtonRelease-1') { self.GetSelection }
        self.Refresh
    end
end


class MountButtons < TkLabelFrame
    attr_writer :Refresher
    
    def Refresh
        @Refresher.call unless @Refresher == nil
    end
    
    def Quit
        exit 0
    end
    
    def DisableMount
        @b_mount.state = 'disabled'
        @MountSelection = nil
    end
    
    def EnableMount select
        @b_mount.state = 'normal'
        @MountSelection = select
    end
    
    def DisableDismount
        @b_dismount.state = 'disabled'
        @DismountSelection = nil
    end
    
    def EnableDismount select
        @b_dismount.state = 'normal'
        @DismountSelection = select
    end
    
    def initialize root
        super(root)
        relief 'ridge'
        borderwidth 2
        padx 30
        pady 10
        height -1
        pack('side' => 'top', :fill=>'x', :expand=>1)
        @b_quit = Button.new(self) do
            borderwidth 2
            width=300
            pack('side' => 'left', :fill=>'none')
            padx 35
            text 'Quit'
            cursor 'hand1'
        end
        @b_quit.bind('1') { self.Quit }
        
        @b_mount = Button.new(self) do
            borderwidth 2
            width=300
            pack('side' => 'left', :fill=>'none')
            padx 30
            text 'Mount'
            state 'disabled'
            cursor 'hand1'
        end
        @b_mount.bind("1") {
            return if @MountSelection == nil
            mnt = Tk.chooseDirectory
            return unless mnt =~ /\S/
            cmd = "gksu \"mount -t nilfs2 -r -o cp=#{@MountSelection['cp']} #{@MountSelection['mount']} #{mnt}\""
            resp = `#{cmd}`
            resp.gsub!("GNOME_SUDO_PASS\n", '')
            resp.gsub!(/sudo: \d+ incorrect password attempt\s*/, '')
            msgBox = Tk.messageBox(
              'type'    => "ok",  
              'icon'    => "info", 
              'title'   => "Command Response",
              'message' => resp
            ) if resp =~ /\S/
            self.Refresh
        }
        
        @b_dismount = Button.new(self) do
            borderwidth 2
            width=300
            pack('side' => 'left', :fill=>'none')
            padx 20
            text 'Dismount'
            state 'disabled'
            cursor 'hand1'
        end
        @b_dismount.bind("1") {
            return if @DismountSelection == nil
            resp = `gksu umount #{@DismountSelection['mount']}`
            resp.gsub!("GNOME_SUDO_PASS\n", '')
            resp.gsub!(/sudo: \d+ incorrect password attempt\s*/, '')
            msgBox = Tk.messageBox(
              'type'    => "ok",  
              'icon'    => "info", 
              'title'   => "Command Response",
              'message' => resp
            ) if resp =~ /\S/
            self.Refresh
        }

        @b_refresh = Button.new(self) do
            borderwidth 2
            width=300
            pack('side' => 'left', :fill=>'none')
            padx 20
            text 'Refresh'
            cursor 'hand1'
        end
        @b_refresh.bind("1") { self.Refresh }
    end
end

class SnapshotButtons < TkLabelFrame
    attr_writer :Refresher
    
    def Refresh
        @Refresher.call unless @Refresher == nil
    end
    
    def Quit
        exit 0
    end
    
    def DisableCreate
        @b_snap.state = 'disabled'
        @CreateSelection = nil
    end
    
    def EnableCreate select
        @b_snap.state = 'normal'
        @CreateSelection = select
    end
    
    def DisableRemove
        @b_unsnap.state = 'disabled'
        @RemoveSelection = nil
    end
    
    def EnableRemove select
        @b_unsnap.state = 'normal'
        @RemoveSelection = select
    end
    
    def initialize root
        super(root)
        relief 'ridge'
        borderwidth 2
        padx 10
        pady 10
        height 50
        pack('side' => 'top', :fill=>'x', :expand=>1)
        @b_quit = Button.new(self) do
            borderwidth 2
            width=300
            pack('side' => 'left', :fill=>'none')
            padx 35
            text 'Quit'
            cursor 'hand1'
        end
        @b_quit.bind('1') { self.Quit }
        
        @b_snap = Button.new(self) do
            borderwidth 2
            width=300
            pack('side' => 'left', :fill=>'none')
            padx 5
            text 'Create Snapshot'
            state 'disabled'
            cursor 'hand1'
        end
        @b_snap.bind("1") {
            return if @CreateSelection == nil
            cmd = "gksu \"chcp ss #{@CreateSelection['mount']} #{@CreateSelection['cp']}\""
            resp = `#{cmd}`
            resp.gsub!("GNOME_SUDO_PASS\n", '')
            resp.gsub!(/sudo: \d+ incorrect password attempt\s*/, '')
            msgBox = Tk.messageBox(
              'type'    => "ok",  
              'icon'    => "info", 
              'title'   => "Command Response",
              'message' => resp
            ) if resp =~ /\S/
            self.Refresh
        }
        
        @b_unsnap = Button.new(self) do
            borderwidth 2
            width=300
            pack('side' => 'left', :fill=>'none')
            padx 5
            text 'Remove Snapshot'
            state 'disabled'
            cursor 'hand1'
        end
        @b_unsnap.bind("1") {
            return if @RemoveSelection == nil
            cmd = "gksu \"chcp cp #{@RemoveSelection['mount']} #{@RemoveSelection['cp']}\""
            resp = `#{cmd}`
            resp.gsub!("GNOME_SUDO_PASS\n", '')
            resp.gsub!(/sudo: \d+ incorrect password attempt\s*/, '')
            msgBox = Tk.messageBox(
              'type'    => "ok",  
              'icon'    => "info", 
              'title'   => "Command Response",
              'message' => resp
            ) if resp =~ /\S/
            self.Refresh
        }

        @b_refresh = Button.new(self) do
            borderwidth 2
            width=300
            pack('side' => 'left', :fill=>'none')
            padx 20
            text 'Refresh'
            cursor 'hand1'
        end
        @b_refresh.bind("1") { self.Refresh }
    end
end


class Mounts < Tk::Tile::Paned
    attr_writer :Refresher

    def Refresh
        @mounts.Refresh
        @checks.Refresh
    end
    
    def initialize root
        super(root, :orient=>'horizontal')
        pack('side' => 'top', :expand=>1, :fill=>'x')
        @mounts = MountList.new(self) do
            pack('side' => 'top', :expand=>0, :fill=>'x')
        end
        @checks = CheckpointList.new(self, '-s') do
            pack('side' => 'top', :expand=>0, :fill=>'x')
        end
        @buts = MountButtons.new(self) do
            pack('side' => 'top', :expand=>0, :fill=>'x')
        end
        @checks.Selected = Proc.new {
            @buts.EnableMount @checks.Selection
            @buts.DisableDismount
        };
        @checks.Deselected = Proc.new {
            @buts.DisableMount
            @buts.DisableDismount
        };
        @mounts.Selected = Proc.new {
            @buts.DisableMount
            @buts.EnableDismount @mounts.Selection
        }
        @mounts.Deselected = Proc.new {
            @buts.DisableMount
            @buts.DisableDismount
        };
        @buts.Refresher = Proc.new { 
            self.Refresh 
            @Refresher.call unless @Refresher == nil
        }
        root.add self, :text => 'Mounts'
    end
end

class Snapshots < TkFrame
    attr_writer :Refresher
    
    def Refresh
        @ss.Refresh
        @cp.Refresh
    end
    
    def initialize root
        super(root)
        @ss = CheckpointList.new(self, '-s')
        @cp = CheckpointList.new(self, '')
        @buts = SnapshotButtons.new(self)
        @cp.Selected = Proc.new {
            @buts.EnableCreate @cp.Selection
            @buts.DisableRemove
        };
        @cp.Deselected = Proc.new {
            @buts.DisableCreate
            @buts.DisableRemove
        };
        @ss.Selected = Proc.new {
            @buts.DisableCreate
            @buts.EnableRemove @ss.Selection
        }
        @ss.Deselected = Proc.new {
            @buts.DisableCreate
            @buts.DisableRemove
        };
        @buts.Refresher = Proc.new {
            self.Refresh 
            @Refresher.call unless @Refresher == nil
        }
        root.add self, :text => 'Snapshots'
    end
end


class App
    def initialize
        root = TkRoot.new { title "Nilfs GUI" }
        f0 = TkFrame.new(root) do
            borderwidth 5
            background "grey"
            pack('side' => 'top', :expand=>1, :fill=>'x')
        end
        nb = Tk::Tile::Notebook.new(f0) do
            width 500
            pack('side' => 'top', :expand=>1, :fill=>'x')
        end
        @mounts = Mounts.new(nb)
        @snaps = Snapshots.new(nb)
        @mounts.Refresher = Proc.new { @snaps.Refresh }
        @snaps.Refresher = Proc.new { @mounts.Refresh }
    end
    
    def checks
        unless `which lscp` =~ /\S/
            msgBox = Tk.messageBox(
              'type'    => "ok",  
              'icon'    => "error", 
              'title'   => "Missing Component",
              'message' => "Cannot process nilfs checkpoints. 'lscp' not found.\nNilfs has not been properly installed on this system.\n"
            )
            exit 1
        end
        unless `which chcp` =~ /\S/
            msgBox = Tk.messageBox(
              'type'    => "ok",  
              'icon'    => "error", 
              'title'   => "Missing Component",
              'message' => "Cannot process nilfs checkpoints. 'chcp' not found.\nNilfs has not been properly installed on this system.\n"
            )
            exit 1
        end
        unless `which gksu` =~ /\S/
            msgBox = Tk.messageBox(
              'type'    => "ok",  
              'icon'    => "error", 
              'title'   => "Missing Component",
              'message' => "Cannot process privileged actions.\n'gksu' has not been installed on this system.\n"
            )
            exit 1
        end
        unless `mount -l -t nilfs2` =~ /\S/
            msgBox = Tk.messageBox(
              'type'    => "ok",  
              'icon'    => "error", 
              'title'   => "No NILFS mounts",
              'message' => "Cannot find any devices mounted that use NILFS\n"
            )
            exit 1
        end
    end
    def run
        Tk.after_idle { self.checks }
        Tk.mainloop
    end
end

app = App.new
app.run
