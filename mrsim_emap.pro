; docformat = 'rst'
;
; NAME:
;    MrSim_CutSlab
;
; PURPOSE:
;+
;   The purpose of this program is to make two columns of plots. The right column will
;   be color plots of all quantities specified by `NAMES` and the left column will be
;   line plots of those quantities taken at `CUT`.::
;       NAME                    DESCRIPTION
;       "Color: [name]"     -   2D image of the quantity specified by "name"
;       "Cut: [name] x=#.#" -   1D vertical cut through the 2D image. #.# locates the cut.
;       "[name] Contours    -   Contours overlayed on the image.
;       "CB: Color [name]   -   Colorbar associated with the 2D image.
;       "VLine [name] #     -   Vertical line overplotted on the image. # = cut number
;       "HLines [name]      -   Horiztonal line overplotted on the image.
;
; :Categories:
;    Bill Daughton, Simulation
;
; :Params:
;       NAMES:              in, required, type=string
;                           The name of the quantitis to be plotted in color.
;       CUT:                in, required, type=int
;                           The x-location (in de) at which the vertical cut will
;                               be taken.
;       TIME:               in, required, type=int
;                           The simulation time for which at which to create the plot.
;                               Igored if `SIM_OBJECT` is given.
;
; :Keywords:
;       C_NAME:             in, optional, type=string, default=''
;                           Name of the data product whose contours are to be 
;                               overplotted on the image.
;       FRACTION:           in, optional, type=float
;                           Fraction of the vectors to be drawn. Used with `VX_NAME`
;                               and `VY_NAME`.
;       HCUT_RANGE:         in, optional, type=fltarr(2)
;                           The horizontal range, in data coordinates, over which to cut.
;                               "Horizontal" is defined by the `HORIZONTAL` keyword. Data
;                               coordinates are determined by the "ion_scale" property
;                               within `SIM_OBJECT`. The default is to take the
;                               appropriate simulation range.
;       HORIZONTAL:         in, optional, type=boolean, default=0
;                           If set, a horizontal cut will be taken. The default is
;                               to take a vertical cut. For an "XY" orientation, "X" is
;                               horizontal, "Y" is vertical. Similar for "XZ", etc.
;                               The orientationis taken from the `SIM_OBJECT` property.
;       NLEVELS:            in, optional, type=int, default=15
;                           The number of contour lines to draw
;       OFILENAME:          in, optional, type=string, default=''
;                           If provided, graphics will be output to a file by this
;                               name. The file extension is used to determine which
;                               type of image to create. "PNG" is the default.
;       SIM_OBJECT:         out, optional, type=object
;                           The "Sim_Object" (or subclass) reference containing the 
;                               simulation data and domain information used in
;                               creating the plot. If not provided, one will be
;                               created according to the `SIM3D` keyword.
;       SIM3D:              in, optional, type=boolean, default=0
;                           If set, and `SIM_OBJECT` is not given, then a 3D
;                               simulation object will be created. The default is
;                               to make 2D simulation object.
;       VCUT_RANGE:         in, optional, type=fltarr(2)
;                           The verical range, in data coordinates, over which to cut.
;                               "Vertical" is defined by the `HORIZONTAL` keyword. Data
;                               coordinates are determined by the "ion_scale" property
;                               within `SIM_OBJECT`. The default is to take the
;                               appropriate simulation range.
;       VX_NAME:            in, optional, type=string, default=''
;                           Name of the x-component of a data product whose vector
;                               field is to be overplotted on the image. Must be used
;                               with `VY_NAME`.
;       VY_NAME:            in, optional, type=string, default=''
;                           Name of the y-component of a data product whose vector
;                               field is to be overplotted on the image. Must be used
;                               with `VX_NAME`.
;       _REF_EXTRA:         in, optional, type=structure
;                           Any keyword accepted Sim_Object::Init(), or any of its
;                               subclasses is also accepted here. Ignored if
;                               `SIM_OBJECT` is present.
;
; :Uses:
;   Uses the following external programs::
;       cgErrorMSG.pro
;       MrSim_LineCut.pro
;       MrSim_ColorSlab.pro
;       MrSim2D__Define.pro
;       MrSim3D__Define.pro
;       MrWindow.pro
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
;       2014/09/01  -   Written by Matthew Argall
;       2014/09/05  -   Added the IM_WIN keyword. - MRA
;-
function MrSim_eMap, type, x, y, dx, dy, $
C_NAME=c_name, $
HGAP=hGap, $
IM_NAME=im_name, $
IM_WIN=im_win, $
NBINS=nBins, $
LAYOUT=layout, $
LOCATION=location, $
SIM_OBJECT=oSim, $
VGAP=vGap, $
_REF_EXTRA=extra
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        if obj_valid(oSim) && arg_present(oSim) eq 0 then obj_destroy, oSim
        if obj_valid(im_win)  then obj_destroy, im_win
        if obj_valid(win2)    then obj_destroy, win2
        if obj_valid(imgTemp) then imgTemp -> Close
        void = cgErrorMSG()
        return, obj_new()
    endif

;-------------------------------------------------------
;Defaults //////////////////////////////////////////////
;-------------------------------------------------------
    ;Set defaults
    if n_elements(nBins)    eq 0 then nBins    = 75
    if n_elements(layout)   eq 0 then layout   = [1,1]
    if n_elements(location) eq 0 then location = 5
    if n_elements(c_name)   eq 0 then c_name   = ''
    if n_elements(im_name)  eq 0 then im_name  = ''
    if n_elements(vGap)     eq 0 then vGap     = 0
    if n_elements(hGap)     eq 0 then hGap     = 0

    ;Create a simulation object
    if n_elements(oSim) eq 0 then begin
        oSim = obj_new(sim_class, time, _STRICT_EXTRA=extra)
        if obj_valid(oSim) eq 0 then return, obj_new()
    endif else begin
        if obj_isa(oSim, 'MRSIM') eq 0 then $
            message, 'SIM_OBJECT must be a subclass of "MrSim"'
    endelse

;-------------------------------------------------------
; Determine Location of Dist Fns ///////////////////////
;-------------------------------------------------------
    xoffset = indgen(1, layout[0])
    yoffset = indgen(1, 1, layout[1])

    ;Calculate the location
    ;   - vertical-horizontal
    case location of
        1: yoffset   = -yoffset                             ;TOP-LEFT
        2: begin                                            ;TOP-CENTER
            xoffset -= layout[0] / 2
            yoffset  = -yoffset
        endcase
        3: begin                                            ;TOP-RIGHT
            xoffset -= layout[0] - 1
            yoffset  = -yoffset
        endcase
        4: yoffset   = reverse(yoffset - layout[1]/2, 3)    ;MIDDLE-LEFT
        5: begin                                            ;MIDDLE-CENTER
            xoffset -= layout[0] / 2
            yoffset  = reverse(yoffset - layout[1]/2, 3)
        endcase
        6: begin                                            ;MIDDLE-RIGHT
            xoffset  = layout[0] - 1
            yoffset  = reverse(yoffset - layout[1]/2, 3)
        endcase
        7: ;Do nothing                                      ;BOTTOM-LEFT
        8: xoffset -= layout[0] / 2                         ;BOTTOM-CENTER
        9: xoffset  = layout[0] - 1                         ;BOTTOM-RIGHT
        else: message, 'LOCATION must be an integer between 1 and 9.'
    endcase
    xoffset = (2*dx + hGap) * rebin(xoffset, 2, layout[0], layout[1])
    yoffset = (2*dy + vGap) * rebin(yoffset, 2, layout[0], layout[1])
        
    
    ;Data locations of distribution functions
    ;   - Saved as [position, index]
    ;   - Position is the IDL definition of the word
    ;   - Index starts with 0 in the upper-right corner, then moves right then down
    nDist                 = product(layout)
    locations             = rebin([x-dx, y-dy, x+dx, y+dy], 4, layout[0], layout[1])
    locations[[0,2],*,*] += xoffset
    locations[[1,3],*,*] += yoffset
    locations             = reform(locations, 4, nDist)
    
;-------------------------------------------------------
; Overview Plot ////////////////////////////////////////
;-------------------------------------------------------
    if im_name ne '' then begin
        ;Create the color plot
        im_win  = MrSim_ColorSlab(im_name, C_NAME=c_name, SIM_OBJECT=oSim)
        im_win -> Refresh, /DISABLE
        
        ;Draw boxes where the distribution functions are being taken.
        theIm = im_win['Color ' + im_name]
        for i = 0, nDist - 1 do begin
            theBin = locations[*,i]
            xpoly  = theBin[[0,2,2,0,0]]
            ypoly  = theBin[[1,1,3,3,1]]
            !Null = MrPlotS(xpoly, ypoly, TARGET=theIm, NAME='Bin ' + strtrim(i, 2), $
                            /DATA, COLOR='White', THICK=2.0)
        endfor
    endif

;-------------------------------------------------------
; Setup Window & Positions /////////////////////////////
;-------------------------------------------------------
    xsize    = 800
    ysize    = 600
    oxmargin = [10,12]
    xgap     = 0
    ygap     = 0
    charsize = 1.5
    win2 = MrWindow(LAYOUT=layout, CHARSIZE=charsize, OXMARGIN=oxmargin, NAME='Dist Win', $
                    XGAP=xgap, YGAP=ygap, XSIZE=xsize, YSIZE=ysize, REFRESH=0)

;-------------------------------------------------------
; Distribution Functions ///////////////////////////////
;-------------------------------------------------------
    ;Velocity space?
    space = strsplit(type, '-', /EXTRACT)
    xaxis = space[0]
    yaxis = space[1]
    tf_xvel = strmid(xaxis, 0, 1) eq 'V'
    tf_yvel = strmid(xaxis, 0, 1) eq 'V'

    xrange = [!values.f_infinity, -!values.f_infinity]
    yrange = [!values.f_infinity, -!values.f_infinity]
    cmax = 0D
    for i = 0, nDist - 1 do begin
        ;Location of bin center
        x_temp = locations[0,i] + dx
        y_temp = locations[1,i] + dy
        
        ;Create the distribution function
        ;   - Remove the colorbar
        imgTemp  = MrSim_eDist(type, x_temp, y_temp, dx, dy, NBINS=nBins, $
                               SIM_OBJECT=oSim, /CURRENT)
        win2    -> Remove, win2['CB: eDist']

        ;Number the distribution
        distNo               = string(i, FORMAT='(i02)')
        imgTemp.NAME         = 'eDist '   + distNo
        win2['BinX'].NAME    = 'BinX '    + distNo
        win2['BinZ'].NAME    = 'BinZ '    + distNo
;        win2['Circles'].NAME = 'Circles ' + distNo
        
        ;Get maximum data range
        ;   - [xy]ranges are only applicable to velocity-space
        ;   - [xy]-space is handled below
        imgTemp -> GetProperty, XRANGE=xr, YRANGE=yr, RANGE=r
        cmax     = cmax  > max(r)
        xRange[0] <= xr[0]
        xRange[1] >= xr[1]
        yRange[0] <= yr[0]
        yRange[1] >= yr[1]
    endfor

;-------------------------------------------------------
; Make Pretty //////////////////////////////////////////
;-------------------------------------------------------
    if tf_xvel eq 0 then xrange = x + [-dx, dx]
    if tf_yvel eq 0 then yrange = y + [-dy, dy]

    ;Determine the aspect ratio of the plots and create positions
    aspect = (yrange[1] - yrange[0]) / (xrange[1] - xrange[0])
    pos  = MrLayout(layout, CHARSIZE=charsize, OXMARGIN=oxmargin, ASPECT=aspect, $
                    XGAP=xgap, YGAP=ygap)

    allIm = win2 -> Get(/ALL, ISA='MrImage')
    foreach imgTemp, allIm do begin
        ;Determine location in layout.
        name = imgTemp.NAME
        i = stregex(name, 'eDist ([0-9]+)', /SUBEXP, /EXTRACT)
        i = fix(i[1])
        
        ;Change the position, axis ranges, and tickmarks
        if tf_xvel then imgTemp.XRANGE = xrange
        if tf_yvel then imgTemp.YRANGE = yrange
        imgTemp -> SetProperty, POSITION=pos[*,i], RANGE=[0, cmax], $
                                XTICKINTERVAL=0.5, XMINOR=5, YTICKINTERVAL=0.5, YMINOR=5
                                
        ;All Except Left Column
        ;   - Do not label y-axis
        if i mod layout[0] ne 0 $
            then imgTemp -> SetProperty, YTITLE='', YTICKFORMAT='(a1)'
        
        ;All Except Bottom Row
        ;   - Do not label x-axis
        if (layout[1] ne 1) && (i+1 le (layout[0]-1)*layout[1]) $
            then imgTemp -> SetProperty, XTITLE='', XTICKFORMAT='(a1)'
    endforeach
    
    if layout[0] gt 3 then begin
        charsize = 1.0
        allText  = win2 -> Get(/ALL, ISA='MrText')
        foreach txt, allText do txt.CHARSIZE=charsize
    endif

;-------------------------------------------------------
; Annotate /////////////////////////////////////////////
;-------------------------------------------------------
    sim_class = obj_class(oSim)
    oSim -> GetProperty, TIME=time, YSLICE=yslice
    oSim -> GetInfo, DTXWCI=dtxwci, DY_DE=dy_de
    
    ;Create a title
    title  = 'eMap ' + type + ' t*$\Omega$$\downci$='
    title += string(dtxwci*time, FORMAT='(f0.1)')
    if sim_class eq 'MRSIM3D' then title += ' y=' + string(yslice*dy_de, FORMAT='(f0.1)') + 'de'
    
    ;Add the title
    !Null = MrText(0.5, 0.965, title, ALIGNMENT=0.5, /CURRENT, $
                   NAME='eMap Title', /NORMAL, CHARSIZE=2)
    
    ;Create a colorbar
    !Null = MrColorbar(CTINDEX=13, RANGE=[0, cmax], POSITION=[0.9, 0.25, 0.92, 0.75], $
                       TITLE='Counts', /CURRENT, NAME='CB: Counts', $
                       /VERTICAL, TLOCATION='Right')

    win2   -> Refresh
    if obj_valid(im_win) then im_win -> Refresh
    if arg_present(oSim) eq 0 then obj_destroy, oSim
    return, win2
end