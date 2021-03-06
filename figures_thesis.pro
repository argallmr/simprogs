; docformat = 'rst'
;
; NAME:
;    Figures_Thesis
;
; PURPOSE:
;+
;   Create figures for my thesis.
;
; :Categories:
;    Bill Daughton, Simulation
;
; :Author:
;    Matthew Argall::
;    University of New Hampshire
;    Morse Hall Room 113
;    8 College Road
;    Durham, NH 03824
;    matthew.argall@wildcats.unh.edu
;
; :History:
;    Modification History::
;       2014/11/06  -   Written by Matthew Argall
;-
;*****************************************************************************************
;+
;   Create Figure 2: 2D simulation.
;-
function FigThesis_AsymmScanBy0_Prox
    compile_opt idl2
    
    catch, the_error
    if the_error ne 0 then begin
        catch, /CANCEL
        if obj_valid(win)  then obj_destroy, win
        if obj_valid(cwin) then obj_destroy, cwin
        void = cgErrorMSG()
        return, obj_new()
    endif
    
    ;Layout
    charsize  = 1.5
    layout    = [2,5]
    oymargin  = [4,4]
    xsize     = 700
    ysize     = 550

;---------------------------------------------------------------------
; 2D Sim, t=32 ///////////////////////////////////////////////////////
;---------------------------------------------------------------------
    theSim    = 'Asymm-Scan/By0'
    time      = 28
    xrange    = [2,-2]
    zrange    = 36.77 + [-5, 5]
    ion_scale = 1
    mva_frame = 1
    coord_sys = 'Magnetopause'
    im_name   = 'Dng_e'
    oSim      = MrSim_Create(theSim, time, XRANGE=xrange, ZRANGE=zrange, $
                             ION_SCALE=ion_scale, MVA_FRAME=mva_frame, $
                             COORD_SYSTEM=coord_sys)
    
;---------------------------------------------------------------------
; Cuts within the Exhaust ////////////////////////////////////////////
;---------------------------------------------------------------------
    cuts = [36.77, 34.9, 33.0]
    
    ;Create cuts of Bx, By, ni, Uix, Ez
    win = MrSim_XProximity(oSim, cuts)
    win -> Refresh, /DISABLE
    
    ;Create a second column
    win -> SetProperty, LAYOUT=layout, CHARSIZE=charsize, OYMARGIN=oymargin, XSIZE=xsize, YSIZE=ysize

    ;Move all graphics into it
    graphics = win -> Get(/ALL, ISA='MrPlot')
    foreach gfx, graphics do begin
        thisLay = gfx.LAYOUT
        colrow  = win -> ConvertLocation(thisLay[2], thisLay[0:1], /PINDEX, /TO_COLROW)
        gfx -> SetLayout, [2, colrow[1]]
    endforeach

;---------------------------------------------------------------------
; Jey Color Plot /////////////////////////////////////////////////////
;---------------------------------------------------------------------
    ;Create a 2D color plot
    cwin = MrSim_ColorSlab(oSim, im_name, C_NAME='Ay', HORIZ_LINE=cuts)
    
    ;Move into the other window
    graphics = cwin -> Get(/ALL)
    foreach gfx, graphics do gfx -> SwitchWindows, win
    obj_destroy, cwin
    
    ;Calculate the positions
    pos = MrLayout(layout, CHARSIZE=charsize, OYMARGIN=oymargin)
    im_pos     = [pos[0,8], pos[1,8], pos[2,0], pos[3,0]]
    im_pos[3] -= 0.05
    
    ;Adjust properties
    win['Color '     + im_name] -> SetProperty, POSITION=im_pos, TITLE=''
    win['CB: Color ' + im_name] -> SetProperty, CBLOCATION='Top', OFFSET=0.5, WIDTH=1.5, TICKINTERVAL=0.05

    win -> SetGlobal, CHARSIZE=charsize
    win -> Refresh
    return, win
end



;+
;   eMap for the Asymm-3D simulation.
;-
function FigThesis_AsymmLarge2D_OhmsLaw, $
FNAME=fname
    compile_opt idl2
    
    catch, the_error
    if the_error ne 0 then begin
        catch, /CANCEL
        if obj_valid(oSim) then obj_destroy, oSim
        if obj_valid(win) then obj_destroy, win
        if obj_valid(win2) then obj_destroy, win2
        if obj_valid(win3) then obj_destroy, win3
        void = cgErrorMSG()
        return, obj_new()
    endif
    
    ;Simulation
    theSim       = 'Asymm-Large-2D'
    tIndex       = 32
    xrange       = [2.0, -2.0]
    zrange       = 150.9 + [-3.0, 3.0]
    coord_system = 'Magnetopause'
    mva_frame    = 1
    ion_scale    = 1
    horizontal   = 1
    component    = 'X'
    
;    theSim       = 'Asymm-Large-2D'
;    tIndex       = 32
;    xrange       = 150.9 + [-3.0, 3.0]
;    zrange       = [-2.0, 2.0]
;    coord_system = 'Simulation'
;    mva_frame    = 1
;    ion_scale    = 1
;    horizontal   = 0
;    component    = 'Z'
    oSim   = MrSim_Create(theSim, tIndex, COORD_SYSTEM=coord_system, MVA_FRAME=mva_frame, $
                          ION_SCALE=ion_scale, XRANGE=xrange, ZRANGE=zrange)

    ;Ohm's Law
    cut       = [150.9, 150.3, 148.4] 
    win       = MrSim_OhmsLaw(oSim, component, cut[0], HORIZONTAL=horizontal)
    win2      = MrSim_OhmsLaw(oSim, component, cut[1], HORIZONTAL=horizontal)
    win3      = MrSim_OhmsLaw(oSim, component, cut[2], HORIZONTAL=horizontal)
    
    nWins = 2
    nCols = 3
    nRows = 4
    win  -> Refresh, /DISABLE
    win  -> SetProperty, LAYOUT=[nCols, nRows], XGAP=3, XSIZE=900, OXMARGIN=[10,11]
    win2 -> Refresh, /DISABLE
    win3 -> Refresh, /DISABLE

;-------------------------------------------------------
; Switch Windows ///////////////////////////////////////
;-------------------------------------------------------
    for iWin = 1, nWins do begin
        ;Select the window
        case iWin of
            1: theWin = win2
            2: theWin = win3
        endcase
        theWin -> SetProperty, LAYOUT=[nCols, nRows], XGAP=1.5, XSIZE=900
    
        ;Step through each graphic in the window.
        graphics = theWin -> Get(/ALL)
        foreach gfx, graphics do begin
            ;Throw away the legends
            if obj_isa(gfx, 'MrLegend') then continue
        
            ;Append the cut-location to the name
            name = gfx.name
            gfx.name = strtrim(cut[iWin-1], 2) + ' ' + name

            ;Change columns
            ;   - So that they do not push objects in WIN to next column
            isOPlot = gfx -> GetOverplot()
            if ~isOPlot then begin
                layout = gfx.layout
                colrow = win -> ConvertLocation(layout[2], layout[0:1], /PINDEX, /TO_COLROW)
                gfx -> SetLayout, [iWin+1, colrow[1]]
            endif else begin
                layout = !Null
            endelse
            
            ;Switch Windows
            gfx -> SwitchWindows, win
        endforeach

        ;Destroy the window
        obj_destroy, theWin
    endfor

;-------------------------------------------------------
; Format Annotations ///////////////////////////////////
;-------------------------------------------------------
    ;Step through each row
    for row = 1, nRows do begin
        yrange = [!values.f_infinity, -!values.f_infinity]
    
        ;Step through each column
        for col = 1, nCols do begin
            ;Find the graphic
            gfx     = win -> FindByColRow([col,row])
            isOPlot = gfx -> GetOverplot(TARGET=target)
            if isOPlot then gfx = target
        
            ;Get the YRANGE
            yr        = gfx.yrange
            yrange[0] = yr[0] < yrange[0]
            yrange[1] = yr[1] > yrange[1]
        endfor
    
        ;Step through each column
        for col = 1, 3 do begin
            ;Find the graphic
            gfx     = win -> FindByColRow([col,row])
            isOPlot = gfx -> GetOverplot(TARGET=target)
            if isOPlot then gfx = target
        
            ;Set Properties
            gfx.yrange = yrange
            if col gt 1 then gfx -> SetProperty, YTITLE='', YTICKFORMAT='(a1)'
;            if col eq 1 then gfx -> SetProperty, YTITLE='E$\downN$'
;            if row eq 1 then gfx -> SetProperty, TITLE='$\Omega$$\downci$$\up-1$=64.0 L=' + string(cut[col-1], FORMAT='(f0.1)') + 'd$\downi$'
;            if row eq nRows then gfx -> SetProperty, XTITLE='N (d$\downi$)'
        endfor

        ;Set Properties
        if row gt 1     then gfx -> SetProperty, TITLE=''
        if row lt nRows then gfx -> SetProperty, XTITLE='', XTICKFORMAT='(a1)'
    endfor

;-------------------------------------------------------
; Move Legends /////////////////////////////////////////
;-------------------------------------------------------
    ;Relocate the legends
    win["Ohm's Law"]               -> SetProperty, LOCATION=8, TARGET=win['150.300 Total E' + component]
    win["Ohm's Law: VxB term"]     -> SetProperty, LOCATION=8, TARGET=win['150.300 E' + component + ' vs. Ec']
    win["Ohm's Law: JxB term"]     -> SetProperty, LOCATION=8, TARGET=win['150.300 E' + component + ' vs. Hall E']
    win["Ohm's Law: div(Pe) term"] -> SetProperty, LOCATION=8, TARGET=win['150.300 E' + component + ' vs. E inert']    
    
    ;Overview
    im_win = MrSim_ColorSlab(oSim, 'Ez', C_NAME='Ay', HORIZ_LINES=cut, $
                             LINE_COLOR=['White', 'Green', 'Red'])

    if obj_valid(oSim) then obj_destroy, oSim
    win -> Refresh
    return, win
end


;+
;   Create the desired figure.
;
; Params:
;       FIGURE:         in, optional, type=string
;                       Figure number of the figure to be created.
;-
function Figures_Thesis, figure, $
SAVE=tf_save
    compile_opt strictarr
    
    catch, the_error
    if the_error ne 0 then begin
        catch, /CANCEL
        if max(obj_valid(win)) then obj_destroy, win
        void = cgErrorMSG()
        return, obj_new()
    endif
    
;---------------------------------------------------------------------
; Info ///////////////////////////////////////////////////////////////
;---------------------------------------------------------------------
    
    ;Current list of figures
    list_of_figures = [['Asymm-Scan-By0', ''], $
                       ['    Prox',       ''], $
                       ['Asymm-Large-2D', ''], $
                       ['    Ohms Law',   '']]
    
    ;Print the list of figures?
    if n_elements(figure) eq 0 then begin
        len = strtrim(max(strlen(list_of_figures[0,*])) > 7, 2)
        print, 'FIGURES', 'DESCRIPTION', FORMAT='(a' + len + ', 4x, a11)'
        print, list_of_figures, FORMAT='(a-' + len + ', 4x, a0)'
        return, obj_new()
    endif

;---------------------------------------------------------------------
; Create Figures /////////////////////////////////////////////////////
;---------------------------------------------------------------------
    
    _figure = strupcase(figure)
    tf_save = keyword_set(tf_save)

    case _figure of
        'ASYMM-SCAN-BY0 PROX':     win = FigThesis_AsymmScanBy0_Prox()
        'ASYMM-LARGE-2D OHMS LAW': win = FigThesis_AsymmLarge2D_OhmsLaw()
        else: message, 'Figure "' + figure + '" not an option.', /INFORMATIONAL
    endcase
    
;---------------------------------------------------------------------
; Save to File? //////////////////////////////////////////////////////
;---------------------------------------------------------------------
    if keyword_set(tf_save) then begin
        ;Create the file name
        froot = '/home/argall/figures/'
        fname = 'MrThesis_' + idl_validname(figure, /CONVERT_ALL)
        fbase = filepath(fname, ROOT_DIR=froot)
        
        ;Save a variety of file types.
        win -> Refresh
        win -> Save, fbase + '_im.png'
        win -> Save, fbase + '.eps'
        win -> Save, fbase + '.ps'
        
        ;Take a snapshot
        win.SAVEAS -> SetProperty, IM_RASTER=0
        win -> Save, fbase + '-ss.png'
    endif
    
    return, win
end