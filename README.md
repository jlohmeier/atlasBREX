# atlasBREX
**Automated template-derived brain extraction for animal MRI**

![alt text](http://www.blog.jlohmeier.de/wp-content/uploads/2017/03/animation_34.gif "Sample")
###### *Developmental (24 months) T2-weighted macaque sample from UNC-Wisconsin Neurodevelopment Rhesus Database (The UNC-Wisconsin Rhesus Macaque Neurodevelopment Database: A Structural MRI and DTI Database of Early Postnatal Development)*

Due to optimization for the human brain, most common skullstripping/brain-extraction methods, such as AFNI's [3dSkullStrip](https://afni.nimh.nih.gov/pub/dist/doc/program_help/3dSkullStrip.html) or FSL's [BET](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/BET),  achieve insufficient results for non-human brains, which then require further manual intervention. Making use of the available brain-extraction from a template-/atlas-volume, this approach implements brain-extraction through reversal transformation of a template-derived mask. Both linear (FLIRT, ANTs) and non-linear (FNIRT, SyN) registration can be performed.

#### _Operational sequence:_
![alt text](http://www.blog.jlohmeier.de/wp-content/uploads/2017/04/170425_workflow.jpg "atlasBREX workflow")

#### Advantages (over similar approaches):
- simple and straightforward usage (with various optional parameters for further optimization)
- time-saving, automated procedure
- multi-step registration (2- or 3-step registration) for improved registration to low resolution spaces and robust brain-extraction for the respective downstream volumes (e.g. functional- and magnitude-volume for fMRI)
- uses robust FSL (FLIRT, FNIRT) or ANTs (SyN) registration algorithms (optional linear and non-linear registration)
- tested with T1-/T2-weighted volumes
- evaluated using developmental and adult marmosets, macaques, rats and mice
- no probability (tissue) mask required
- includes various (optional) strategies for robust registration: 
  * bias field correction (N4)
  * intensity normalization (3dUnifize)
  * segmentation draft dilation: introduce dilated drafts as reference and target volumes, effectively reducing extracranial tissue (in comparison to the respective whole-head volumes)

## Requirements:
- [FSL (FMRIB Software Library)](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
- Bash >= 4

*Optional:*
- [AFNI (Analysis of Functional NeuroImages)](https://afni.nimh.nih.gov/afni/): 3dAutomask, 3dUnifize
- [ANTs (Advanced Normalization Tools)](https://github.com/stnava/ANTs): antsRegistration, antsApplyTransforms, N4BiasFieldCorrection, ImageMath and antsRegistrationSyN

## Usage:

```
bash atlasBREX.sh -b <input> -nb <input> -h <input> -f <input>
(no multi-line commands)
```

#### Practical example:

- b_template_brain.nii.gz (brain-extracted template)
- nb_template.nii.gz (whole-head template)
- sj_170308_1.nii.gz (subject #1)
- sj_170308_2.nii.gz (subject #2)
- sj_170308_3.nii.gz (subject #3)

Copy all gzipped (.nii.gz) NIFTI volumes and *atlasBREX.sh* into a **common** folder. There should be no directory or file containing *'orig'*, *'temp'* or *'_.nii.gz'* in this folder.

**1. Step**: Run atlasBREX with linear registration using the `-f n` flag to determine a reasonable fractional intensity value. AtlasBREX will propose you 3 images for selection (Choose the option with least extracranial tissue) during this pilot-run. This step will usually take only a few minutes. 
- use the `-nrm 1` flag for T1W intensity normalization, where AFNI is available. Improves provisional brain-extraction and registration accuracy.
- if brain regions appear clipped using FLIRT/FNIRT, try to adjust the fractional intensity parameter or reduce the FOV using `robustfov` (FSL) to improve preliminary brain-extraction. 
- if available, try `-reg 2` for the ANTs registration framework, particularly if you encounter issues with T1-weighted images. 
- single-subject or **averaged templates** (ABSORB: Atlas Building by Self-Organized Registration and Bundling) with similar contrast patterns frequently provide better results.

```
bash atlasBREX.sh -b b_template_brain.nii.gz -nb nb_template.nii.gz -h sj_170308_1.nii.gz -f n
```

**2. Step**: Now that a suitable fractional intensity value is known, we can run atlasBREX with non-linear registration on all subjects in an automated and unattended manner:

```
for file in *'sj_'*'.nii.gz'*
  do
    bash atlasBREX.sh -b b_template_brain.nii.gz -nb nb_template.nii.gz -h $file -reg 1 -w 5,5,5 -msk a,0,0 -f 0.2
  wait
done
```

- Sample dataset: https://github.com/jlohmeier/atlasBREX/tree/master/demonstration
- Example helper script: https://github.com/jlohmeier/atlasBREX/blob/master/example.sh
- [Visual (hands-on) walkthrough w/ rhesus macaque](http://www.blog.jlohmeier.de/wp-content/uploads/2017/03/visual_walkthrough.jpg) (*public sample data from Allen Institute for Brain Science*)

## Arguments:

**Compulsory arguments:**

    -b          brain-extracted atlas or template
    -nb         whole-head (non-brain) atlas or template
    -h          high resolution 3D volume
    -f          fractional intensity threshold [n > 0] 
                for preliminary brain-extraction (e.g. -f 0.2).
                [-f n] proposes 3 default thresholds for interactive selection. 
                For multi-step registration, different values for high-res, 
                low-res and native volume may be entered (e.g. -f 0.2,0.5,0.8)

**Optional arguments:**

    -l          low resolution 3D volume (3-step)
    -n          native (functional) space 3D/4D volume  (2-/3-step)
    -t/-tmp     disable removal [1] of temporary files (default: 0) 
    -w/-wrp     while FNIRT (FSL) requires a warp-resolution (e.g. -wrp 5,5,5),
                SyN (ANTs) requires a warp [-wrp 1] flag (e.g. -wrp 1 -reg 2)
    -r/-reg     either FNIRT w/ bending energy for regularization [-reg 0], 
                FNIRT w/ membrane energy for regularization [-reg 1], 
                ANTs w/ [-reg 2] or w/o [-reg 3] N4BiasFieldCorrection 
                (default: 1) 
    -rot        disable [1] rotation to MNI152 (default: 0) 
    -msk        mask binarization threshold (in %) for fslmaths 
                w/ optional erosion and dilation (e.g. -msk b,10,0,0)
                [-msk b,[n > 0] for threshold, [0-9] for n-times erosion,
                [0-9] for n-times dilation] or 3dAutomask (e.g. -msk a,0,0) 
                [-msk a,[0-9] for n-times erosion,[0-9] for n-times dilation]  
                (default: b,0.5,0,0)
    -vox        interim voxel size adjustment [-vox 1] (default: 0)
    -nrm        interim intensity normalization w/ T1 [-nrm 1] or T2 [-nrm 2]
    -dil        dilate segmentation draft from linear registration n-times 
                and use as baseline for non-linear registration (e.g. -dil 4)

## Notes/Troubleshooting:
- use `-help`/`--help` for further details.
- see *log.txt* for a summary after running the script.
- use `-f n` during the test-run to determine a suitable fractional intensity threshold. atlasBREX will propose 3 brain-extractions and lets you choose at the beginning of the procedure.
- use `-nrm` flag for (interim) intensity normalization (AFNI required) for T1W and T2W volumes. In most cases this will yield better preliminary brain-extraction and registration results.
- use `-dil` flag in case of registration failures during non-linear registration. (n >= 4 as recommended starting point)
- each (non-template) input volume will be brain-extracted, appended with a "_brain.nii.gz" or "_brain_lin.nii.gz" suffix.
- recommended settings (for accuracy): `-reg 1 -w 5,5,5`(FNIRT with membrane energy for regularization) or `-reg 2 -w 1`(SyN w/ bias field correction).
- adjust warp resolution if you encounter issues with memory (e.g. std::bad_alloc).
- non-linear transformation matrix and warp file are preserved (to reduce total computation time for brain-extraction of multiple downstream input volumes).
- if the result appears miswarped, review your volumes for inconsistencies regarding q- and s-form within NIFTI headers.
- results depend on the template and its derived mask, linear/non-linear (incl. warp-resolution) registration, applied algorithms (FSL or ANTs), quality and resolution of the input volumes and multi-step registration (particularly for functional volumes).
- number of threads can be set within the script for ANTs' parallel computing.
- Bash >=4 required; OSX requires an update (e.g. `brew install bash`, check your bash version afterwards `bash --version`) and call the script using `bash atlasBREX.sh`; ignore (standard_in) 1: syntax error on OSX;

### Links:
- Atlas: http://www.lead-dbs.org/?page_id=1096
- Atlas: https://scalablebrainatlas.incf.org/main/index.php
- FSL: http://fsl.fmrib.ox.ac.uk
- AFNI: https://afni.nimh.nih.gov/afni/
- ANTs: https://github.com/stnava/ANTs

### Open source: BSD-3-Clause
If you use this application or part of its source code, cite *atlasBREX* with a reference to this Github page.

*[work in submission]*
