#' Plot mc+cell graph using pre-defined mc colorization
#'
#' @param mc2d_id mc2d object to plot
#' @param legend_pos position of legend
#' @param plot_edges plot edges between metacells (true by default)
#' @param min_edge_l (defulat 0) length of edges that are consider long
#' @param edge_w width of long edges
#' @param short_edge_w with of short edges
#' @param show_mcid should metacell id be plotted
#' @param cell_outline should single cell be drawn with outline
#' @param sc_cex size of single cell points
#' @param fig_fn override the default file name in the scfig directory
#' @param filt_mc optionally a factor defining which MCs to plot
#' @param colors can provide color vector to overide the default mc@colors
#' @param 
#'
#' @export
mcell_mc2d_plot = function(mc2d_id, legend_pos="topleft", plot_edges=T, min_edge_l=0, edge_w = 1, short_edge_w=0, show_mcid = T, cell_outline=F, colors=NULL, fig_fn = NULL, fn_suf="", sc_cex=1, filt_mc=NULL)
{
	mcp_2d_height = get_param("mcell_mc2d_height")
	mcp_2d_width = get_param("mcell_mc2d_width")
	mcp_2d_plot_key = get_param("mcell_mc2d_plot_key")
	mcp_2d_cex = get_param("mcell_mc2d_cex")
	mcp_2d_legend_cex = get_param("mcell_mc2d_legend_cex")

	mc2d = scdb_mc2d(mc2d_id)
	if(is.null(mc2d)) {
		stop("missing mc2d when trying to plot, id ", mc2d_id)
	}
	mc = scdb_mc(mc2d@mc_id)
	if(is.null(mc)) {
		stop("missing mc in mc2d object, id was, ", mc2d@mc_id)
	}
	if(!is.null(filt_mc)) {
		f_sc = filt_mc[mc@mc[names(mc2d@sc_x)]]
		mc2d@sc_x[!f_sc] = NA
		mc2d@sc_y[!f_sc] = NA
		mc2d@mc_x[!filt_mc] = NA
		mc2d@mc_y[!filt_mc] = NA
	}
	if(is.null(fig_fn)) {
		fig_fn = scfigs_fn(paste(mc2d_id,fn_suf,sep=""), ifelse(plot_edges, "2d_graph_proj", "2d_proj")) 
	}
	.plot_start(fig_fn, w=mcp_2d_width, h = mcp_2d_height)
	#png(fig_fn, width = mcp_2d_width, height = mcp_2d_height)
	if(is.null(colors)) {
		cols = mc@colors
	} else {
		cols = colors
	}
	cols[is.na(cols)] = "gray"
	if(cell_outline) {
		plot(mc2d@sc_x, mc2d@sc_y, pch=21, bg=cols[mc@mc[names(mc2d@sc_x)]], cex=sc_cex, lwd=0.5)
	} else {
		plot(mc2d@sc_x, mc2d@sc_y, pch=19, col=cols[mc@mc[names(mc2d@sc_x)]], cex=sc_cex)
	}
	fr = mc2d@graph$mc1
	to = mc2d@graph$mc2
	if (plot_edges) {
		dx = mc2d@mc_x[fr]-mc2d@mc_x[to]
		dy = mc2d@mc_y[fr]-mc2d@mc_y[to]
		f = sqrt(dx*dx+dy*dy) > min_edge_l
		segments(mc2d@mc_x[fr], mc2d@mc_y[fr], mc2d@mc_x[to], mc2d@mc_y[to], 
					lwd=ifelse(f, edge_w, short_edge_w))
	}
	points(mc2d@mc_x, mc2d@mc_y, cex= 3*mcp_2d_cex, col="black", pch=21, bg=cols)
	if(show_mcid) {
		text(mc2d@mc_x, mc2d@mc_y, 1:length(mc2d@mc_x), cex=mcp_2d_cex)
	}

	if(nrow(mc@color_key)!=0 & mcp_2d_plot_key) {
		key = mc@color_key[ mc@color_key$color %in% mc@colors, ]
#		if(nrow(key!=0)) {
		if(!is.null(key) & is.vector(key) & nrow(key) != 0) {
#group	gene	color	priority	T_fold
		gmark = tapply(key$gene, key$group, paste, collapse=", ")
		gcol = unique(data.frame(col=key$color, group=key$group))
		rownames(gcol) = gcol$group
		if(is.vector(gmark)) {
			gmark = gmark[order(names(gmark))]
		}
		if(legend_pos == "panel") {
			dev.off()
			fig_fn = sub(".png", ".2d_proj_legend.png", fig_fn)
			png(fig_fn, width = 600, height= length(gmark)*40+400)
			plot.new()
			legend_pos = "topleft"
		}
		legend(legend_pos,
				legend=gsub("_", " ", paste0(names(gmark), ": ", gmark)),
				pch=19, cex=mcp_2d_legend_cex,
				col=as.character(gcol[names(gmark), 'col']), bty='n')
		}
	}

	dev.off()
}


#' Plot mc+cells using pre-defined mc colorization, breakdown by given metadata field (e.g. patient)
#'
#' @param mc2d_id mc2d object to use for plot
#' @param mat_id mat object matching mc2d_id that contains the cells metadata information
#' @param meta_field field name (in mat cell_metadata slot) to split cells by
#' @param meta_data_vals actual named vector (names are cells, values are the metadata to factor on), if this is not null, the meta_field is not used
#' @param single_plot output all panels in a single plot or plot per panel (T)
#' @param filter_values to filter meta_field values by (NULL)
#' @param filter_name name to add to plots (NULL)
#' @param ncols number of panels in column (if single_plot is true), automatically calculate if NULL
#' @param neto_points plot without a box and a title (relevant if single_plot=F)
#'
#' @export
mcell_mc2d_plot_by_factor = function(mc2d_id, mat_id, meta_field, meta_data_vals = NULL, single_plot = T, filter_values = NULL, filter_name = NULL, ncols=NULL, neto_points=F, colors=NULL, base_dir= NULL, filt_mc = NULL, na_color="white")
{
  mcp_2d_height = get_param("mcell_mc2d_height")
  mcp_2d_width = get_param("mcell_mc2d_width")
  mcp_2d_plot_key = get_param("mcell_mc2d_plot_key")
  mcp_2d_cex = 2 * get_param("mcell_mc2d_cex")
  mcp_2d_legend_cex = get_param("mcell_mc2d_legend_cex")

  bg_col="grey90"

  mc2d = scdb_mc2d(mc2d_id)
  if(is.null(mc2d)) {
    stop("missing mc2d when trying to plot, id ", mc2d_id)
  }
  mc = scdb_mc(mc2d@mc_id)
  if(is.null(mc)) {
    stop("missing mc in mc2d object, id was, ", mc2d@mc_id)
  }

  mat = scdb_mat(mat_id)
  if (is.null(mat)) {
    stop(sprintf("missing mat (id = %s) for metadata info when plotting %s", mat_id, mc2d_id))
  }

	if(!is.null(filt_mc)) {
		f_sc = filt_mc[mc@mc[names(mc2d@sc_x)]]
		mc2d@sc_x[!f_sc] = NA
		mc2d@sc_y[!f_sc] = NA
		mc2d@mc_x[!filt_mc] = NA
		mc2d@mc_y[!filt_mc] = NA
	}

  if (any(mat@cells != mc@cell_names)) {
    stop(sprintf("cells mismatch between mc2d mc (id = %s) and mat (id = %s) objects", mc2d_id, mat_id))
  }

  if(!is.null(meta_data_vals)) {
    c_by_f = split(names(mc@mc), meta_data_vals[names(mc@mc)])
  } else {
    c_by_f = split(names(mc@mc), mat@cell_metadata[names(mc@mc), meta_field])
  }
  if (is.null(filter_values)) {
    filter_values = names(c_by_f)
	 filter_values = sort(filter_values)
  }
  else {
    c_by_f = c_by_f[names(c_by_f) %in% filter_values]
  }

	if(is.null(colors)) {
		cols = mc@colors
	} else {
		cols = colors
	}
  cols[is.na(cols)] = na_color

  if (single_plot) {
    ny = ifelse(is.null(ncols), floor(sqrt(length(c_by_f))), ncols)
    nx = ceiling((length(c_by_f)/ny))

	 if(is.null(base_dir)) {
    	fig_nm = scfigs_fn(mc2d_id, sprintf("2d_proj_%sall", ifelse(is.null(filter_name), "", paste0(filter_name, "_"))), sprintf("%s/%s.by_%s", .scfigs_base, mc2d_id, meta_field))
	 } else {
		fig_nm = sprintf("%s/2d_proj_by_%s.png", base_dir, meta_field)
	 }
    .plot_start(fig_nm, w=mcp_2d_width, h=mcp_2d_width / ny * nx)

    layout(matrix(1:(nx*ny), nx, ny, byrow=T))
    par(mar=c(0.5,0.5,3,0.5))
  } 

  for (meta_field_v in filter_values) {
    ccells = c_by_f[[meta_field_v]]

    if (!single_plot) {
		if(is.null(base_dir)) {
      	fig_nm = scfigs_fn(mc2d_id, sprintf("2d_proj_%s", meta_field_v, ifelse(is.null(filter_name), "", paste0(filter_name, "_"))), sprintf("%s/%s.by_%s", .scfigs_base, mc2d_id, meta_field))
	 	} else {
			fig_nm = sprintf("%s/2d_proj_by_%s_%s.png", base_dir, meta_field, meta_field_v)
	 	}
      .plot_start(fig_nm, w=mcp_2d_width, h=mcp_2d_height)
		if(neto_points) {
    		par(mar=c(0,0,0,0))
		} else {
      	par(mar=c(0.5, 0.5, ifelse(neto_points, 0.5, 3), 0.5))
	   }
    }

    #col=cols[mc@mc]
    plot(mc2d@sc_x, mc2d@sc_y, cex=mcp_2d_cex, pch=21, col=bg_col, bg=bg_col, xlab="", ylab="", xaxt='n', yaxt='n', bty=ifelse(!single_plot & neto_points, 'n', 'o'))
    points(mc2d@sc_x[ccells], mc2d@sc_y[ccells], cex= mcp_2d_cex, lwd=0.5, pch=19, col=cols[mc@mc[ccells]])
    #text(mc2d@mc_x, mc2d@mc_y, 1:length(mc2d@mc_x), cex=mcp_2d_cex)

    if (single_plot || !neto_points) {
    	title(main=sprintf("%s (%d)", meta_field_v, length(ccells)), cex.main=1.2*mcp_2d_legend_cex)
    }
    if (!single_plot) {

      if(nrow(mc@color_key) != 0 & mcp_2d_plot_key & !neto_points) {
        key = mc@color_key[ mc@color_key$color %in% mc@colors, ]
		
#			if(!is.null(key) & is.vector(key) & nrow(key) != 0) {
        #group	gene	color	priority	T_fold
        gmark = tapply(key$gene, key$group, paste, collapse=", ")
        gcol = unique(data.frame(col=key$color, group=key$group))
        rownames(gcol) = gcol$group
		  if(is.vector(gmark)) {
        	  gmark = gmark[order(names(gmark))]
		  }
        legend("topleft",
               legend=gsub("_", " ", paste0(names(gmark), ": ", gmark)),
               pch=19, cex=mcp_2d_legend_cex,
               col=as.character(gcol[names(gmark), 'col']), bty='n')
		}

      dev.off()
	}
  }

  if (single_plot) {
    dev.off()
  }

}

#' Plot the (log2) metacell footprint value of the selected gene on the 2d projection
#'
#' @param mc2d_id mc2d object to use for plot
#' @param gene gene name to plot
#' @param show_mc_ids plot metacell ids (false by default)
#' @param show_legend plot color bar legend (true by default)
#' @param neto_points do not plot box, title and legend
#' @param color_cells (F default) should cells be colored by UMIs
#' @param mat_ds downsampled matrix for coloring cells
#' @param zero_sc_v num of umis to consdier as 0 for cell coloring (def 0)
#' @param one_sc_v num of umis to consdier as 1 for cell coloring (def 1)
#' @param tw_sc_v num of umis to consdier as 1 for cell coloring (def 2)
#' @param base_dir override the default base directory if not null
#' @param filt_mc (defulat is NULL) - factor to determine which metacells to plot
#'
#' @export
#'
mcell_mc2d_plot_gene = function(mc2d_id, gene, 
		show_mc_ids=F, show_legend=T, neto_points=F, 
		max_lfp = NA, min_lfp=NA, color_cells = F, mat_ds = NULL,
		zero_sc_v = 0, one_sc_v = 1, two_sc_v=2, 
		base_dir = NULL,
		filt_mc = NULL)
{
	height = get_param("mcell_mc2d_gene_height")
	width = get_param("mcell_mc2d_gene_width")
	mc_cex = get_param("mcell_mc2d_gene_mc_cex")
	sc_cex = get_param("mcell_mc2d_gene_cell_cex")
	colspec = get_param("mcell_mc2d_gene_shades")
	if(is.na(max_lfp)) {
		max_lfp = get_param("mcell_mc2d_gene_max_lfp")
		min_lfp = -max_lfp
	}
	
	mc2d = scdb_mc2d(mc2d_id)
	if(is.null(mc2d)) {
		stop("missing mc2d when trying to plot, id ", mc2d_id)
	}
	mc = scdb_mc(mc2d@mc_id)
	if(is.null(mc)) {
		stop("missing mc in mc2d object, id was, ", mc2d@mc_id)
	}
	if(!is.null(filt_mc)) {
		f_sc = filt_mc[mc@mc[names(mc2d@sc_x)]]
		mc2d@sc_x[!f_sc] = NA
		mc2d@sc_y[!f_sc] = NA
		mc2d@mc_x[!filt_mc] = NA
		mc2d@mc_y[!filt_mc] = NA
	}
	
	if (!(gene %in% rownames(mc@mc_fp))) {
		stop(sprintf("gene %s not found in mc object id %s mc_fp table", gene, mc2d@mc_id))
	}
	
	x = pmin(pmax(log2(mc@mc_fp[gene, ]), min_lfp), max_lfp) - min_lfp
	shades = colorRampPalette(colspec)(100 * (max_lfp-min_lfp) + 1)
	mc_cols = shades[round(100 * x) + 1] 

	if(is.null(base_dir)) {
		fig_fn = scfigs_fn(mc2d_id, sub("\\/","",gene), sprintf("%s/%s.genes", .scfigs_base, mc2d_id))
	} else {
		gene_nm = sub("\\/", "", gene)
		fig_fn = sprintf("%s/%s.png", base_dir, gene_nm)
	}
	.plot_start(fig_fn, w = width * ifelse(show_legend & !neto_points, 1.25, 1), h = height)
	if (show_legend & !neto_points) {
		layout(matrix(c(1,1:3), nrow=2, ncol=2), widths = c(4,1))
	}
	
	if (neto_points) {
		par(mar=c(1,1,1,1))
	} else {
		par(mar=c(4,4,4,1))
	}

	sc_cols = "gray80"
	if(color_cells & !is.null(mat_ds)) {
		cnms = intersect(names(mc2d@sc_x), colnames(mat_ds))
		sc_umi = rep(NA, length(mc2d@sc_x))
		names(sc_umi) = names(mc2d@sc_x)
		sc_umi[cnms] = mat_ds[gene, cnms]
		sc_umi[is.na(sc_umi)] = 0
		base_shade = 1+floor(length(shades)*max_lfp/(max_lfp-min_lfp))
		l_shade = length(shades) - base_shade - 1
		collow = shades[base_shade + floor(l_shade/4)]
		colmid = shades[base_shade + floor(l_shade/2)]
		colhigh = shades[base_shade + floor(3*l_shade/4)]
		sc_cols = ifelse(sc_umi<=zero_sc_v,"gray80",ifelse(sc_umi<=one_sc_v, collow, ifelse(sc_umi<=two_sc_v, colmid, colhigh)))
	}

	plot(mc2d@sc_x, mc2d@sc_y, pch=19, cex=sc_cex, col=sc_cols, xlab="", ylab="", main=ifelse(neto_points, "", gene), cex.main=mc_cex, bty=ifelse(neto_points, 'n', 'o'), xaxt=ifelse(neto_points, 'n', 's'), yaxt=ifelse(neto_points, 'n', 's'))
	points(mc2d@mc_x, mc2d@mc_y, pch=21, bg=mc_cols, cex=mc_cex)
	
	if (show_mc_ids) {
		text(mc2d@mc_x, mc2d@mc_y, seq_along(mc2d@mc_y), cex=mc_cex * 0.5)
	}
	
	if (show_legend & !neto_points) {
		par(mar=c(4,1,4,1))
		plot_color_bar(seq(min_lfp, max_lfp, l=length(shades)), shades, show_vals_ind=c(1, 100 * max_lfp + 1, 200 * max_lfp + 1))
	}
	
	dev.off()
}
