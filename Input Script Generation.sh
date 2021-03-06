#!/bin/bash -f

MYDIR="generated_geometries"
OUTDIR="/tmp/$USER"
OUTPUT="/home/$USER/$MYDIR"

LISTTEMP="300" # Temperature (K)
LISTPRESSURE="0.01" # Pressure (kcal/mol/A)
LISTHOLE="1 2 3 4 5" #(number of pores)
LISTSEED="1 2 3" # equilibrium

Ctype="1"
CLtype="2"
Htype="3"
Otype="4"
pistontype="5"
NAtype="6"
zCtype="7"
zHtype="8"
atm="-0.000041"
waterbond="1"
waterangle="1"

for temp in $LISTTEMP
do
	for press in $LISTPRESSURE
	do
		for hole in $LISTHOLE
		do
			for seed in $LISTSEED
			do
				FILENAME="hydrogen.pore$hole.seed$seed"
				rm -f $OUTPUT/$FILENAME.in
				cat >$OUTPUT/$FILENAME.in << EOF
# March 20, 2016
# Hydrogenated graphene pore desalination, changing porosity and allowing membrane deformation

# System setup
atom_style  full
units   real
dimension 3
boundary p p p

# Read/analyze init geometry
read_data graphene.hydrogen.pore$hole.dat
variable natoms equal "count(all)"

# Define interaction parameters
pair_style hybrid lj/cut/tip4p/long $Otype $Htype $waterbond $waterangle 0.1546 13.0 airebo 3.0 0 1
pair_modify tail yes
bond_style harmonic
angle_style harmonic
dihedral_style none

# ------------- Regions and Groups ---------------- 
group carbon    	type $Ctype $pistontype # Membrane and piston carbon atoms
group ox        	type $Otype				# Water oxygen
group hy        	type $Htype				# Water hydrogen
group na        	type $NAtype			# Salt sodium
group cl        	type $CLtype			# Salt chloride

group h_hydrogen    type $zHtype			# Pore hydrogen
group c_hydrogen    type $zCtype			# Pore carbon
group hydrogengroup union h_hydrogen c_hydrogen

# Defining the positions of all four carbon planes
variable zpiston1 equal -50
variable zmembrane1 equal 0
variable zpiston2 equal "20"

# Defining the piston and the membrane carbons
variable zmin equal \${zpiston1}-1.0
variable zmax equal \${zpiston1}+1.0
region piston1zone   block INF INF INF INF \${zmin} \${zmax} units box

variable zmin equal \${zmembrane1}-1.0
variable zmax equal \${zmembrane1}+1.0
region  membrane1zone  block INF INF INF INF \${zmin} \${zmax} units box

variable zmin equal \${zpiston2}-1.0
variable zmax equal \${zpiston2}+1.0
region piston2zone   block INF INF INF INF \${zmin} \${zmax} units box

group piston1			region piston1zone		# whole piston1 (carbon)
group piston2			region piston2zone		# whole piston2 (carbon)
group bothpistons       union piston1 piston2
group membrane1_atoms	region membrane1zone 
group totalmembrane     union membrane1_atoms
group not_hy subtract all hy

# Defining fixed membrane atom
group fixedatoms id 5990
group membrane1_free subtract membrane1_atoms fixedatoms

# Defining water groups
group water			union ox hy
group saltwater		union water na cl
group notsaltwater	subtract all saltwater

# Defining group of atoms in Nose-Hoover thermostat
group thermostat_target union saltwater membrane1_free piston1 piston2

# Setting hydrogen charges (from Birkett et al.)
set group c_hydrogen charge -0.115
set group h_hydrogen charge 0.115

# Setting water charges
set group ox charge -1.0484
set group hy charge  0.5242
set group na charge  1.
set group cl charge -1.

# ------------- Coefficients ----------------

# AIREBO:
pair_coeff * * airebo CH.airebo_real C NULL NULL NULL NULL NULL C H

# Lennard-Jones: sigmaAB = (1/2)(sigmaAA + sigmaBB), epsilonAB = (epsilonAA*epsilonBB)^0.5
# Syntax: pair_coeff atom_i atom_j epsilon sigma
pair_coeff $Ctype $CLtype lj/cut/tip4p/long 0.031702 4.2821			# C-CL
pair_coeff $Ctype $Htype lj/cut/tip4p/long 0 0						# C-H
pair_coeff $Ctype $Otype lj/cut/tip4p/long 0.12613 3.2793			# C-O
pair_coeff $Ctype $pistontype lj/cut/tip4p/long 0.019208 3.3749		# C-piston
pair_coeff $Ctype $NAtype lj/cut/tip4p/long 0.12027 2.8293			# C-NA
pair_coeff $CLtype $CLtype lj/cut/tip4p/long 0.0117 5.1645			# CL-CL
pair_coeff $CLtype $Htype lj/cut/tip4p/long 0 0						# CL-H
pair_coeff $CLtype $Otype lj/cut/tip4p/long 0.046549 4.1617			# CL-O
pair_coeff $CLtype $pistontype lj/cut/tip4p/long 0.0070888 4.2572	# CL-piston
pair_coeff $CLtype $NAtype lj/cut/tip4p/long 0.044388 3.7117		# CL-NA
pair_coeff $CLtype $zCtype lj/cut/tip4p/long 0.028679 4.3573		# CL-zC
pair_coeff $CLtype $zHtype lj/cut/tip4p/long 0.018766 3.7923		# CL-zH
pair_coeff $Htype $Htype lj/cut/tip4p/long 0 0						# H-H
pair_coeff $Htype $Otype lj/cut/tip4p/long 0 0						# H-O
pair_coeff $Htype $pistontype lj/cut/tip4p/long 0 0					# H-piston
pair_coeff $Htype $NAtype lj/cut/tip4p/long 0 0						# H-NA
pair_coeff $Htype $zCtype lj/cut/tip4p/long 0 0						# H-zC
pair_coeff $Htype $zHtype lj/cut/tip4p/long 0 0						# H-zH
pair_coeff $Otype $Otype lj/cut/tip4p/long 0.1852 3.1589			# O-O
pair_coeff $Otype $pistontype lj/cut/tip4p/long 0.028203 3.2545		# O-piston
pair_coeff $Otype $NAtype lj/cut/tip4p/long 0.1766 2.7089			# O-NA
pair_coeff $Otype $zCtype lj/cut/tip4p/long 0.1141 3.3544			# O-zC
pair_coeff $Otype $zHtype lj/cut/tip4p/long 0.074663 2.7894			# O-zH
pair_coeff $pistontype $pistontype lj/cut/tip4p/long 0.004295 3.35	# piston-piston
pair_coeff $pistontype $NAtype lj/cut/tip4p/long 0.026894 2.8045	# piston-NA
pair_coeff $pistontype $zCtype lj/cut/tip4p/long 0.017376 3.45		# piston-zC
pair_coeff $pistontype $zHtype lj/cut/tip4p/long 0.01137 2.885		# piston-zH
pair_coeff $NAtype $NAtype lj/cut/tip4p/long 0.1684 2.2589			# NA-NA
pair_coeff $NAtype $zCtype lj/cut/tip4p/long 0.1088 2.9044			# NA-zC
pair_coeff $NAtype $zHtype lj/cut/tip4p/long 0.071196 2.3395		# NA-zH

kspace_style pppm/tip4p 1.0e-4 # Long range Coulombic interaction solver

# Bond and angles coeffs
# Syntax: angle_coeff N spring_constant theta_0
bond_coeff * 0.0 0.0 # Zero by default
angle_coeff * 0.0 0.0 # Zero by default

# Water
bond_coeff  $waterbond 0.0 0.9572 # H2O bond (TIP4P-2005)
angle_coeff $waterangle 0.0 104.52  # H2O angle (TIP4P-2005)

neighbor        2.0 bin
neigh_modify	every 1 delay 10 check yes

# ------------- Setup ----------------
# For the equilibration phase, keep the piston rigid.
fix pistonfreeze bothpistons setforce 0.0 0.0 0.0
# Ensure thermostat looking at relevant atoms by defining new temperature calculation for only moveable atoms
compute selective_thermostat thermostat_target temp
# And require LAMMPS to use this compute when doing anything related to temperature
thermo_modify temp selective_thermostat

# ------------- Minimization ----------------        
thermo_style one       
thermo 10
run 0

fix freezewater saltwater setforce 0.0 0.0 0.0
minimize 1.0e-4 1.0e-6 1000 1000
unfix freezewater

fix relax all box/relax x 0.0 y 0.0
minimize 1.0e-4 1.0e-6 100 1000
unfix relax
unfix pistonfreeze

# ------------- Equilibration ----------------
fix pistonkeep bothpistons setforce 0.0 0.0 NULL

# Squeezing water between pistons (150 MPa each)
fix piston1thrust piston1 aveforce NULL NULL 0.0467
fix piston2thrust piston2 aveforce NULL NULL -0.0467
fix 1 water shake 1.0e-4 100 0 b $waterbond a $waterangle
fix NVTequilib thermostat_target nvt temp 300 300 50
timestep 0.5
# Equilibriate for seed length: 40, 50, 60 ps
thermo 1000
dump    equilibdump not_hy atom 100 $FILENAME.equilib.lammpstrj
variable equibtime equal 80000+$seed*20000
run \${equibtime}

write_restart $FILENAME.equilb.restart
print "Equilibration completed."
unfix NVTequilib
undump equilibdump

# ------------- Dynamics --------
unfix piston1thrust
unfix piston2thrust

# Pressurize pistons and set temperature target
fix piston1push piston1 aveforce NULL NULL $press
fix piston2push piston2 aveforce NULL NULL $atm
fix NVT thermostat_target nvt temp $temp $temp 50
thermo 1000

# Counting the number of waters and ions in the feed region
region feedzone block INF INF INF INF INF \${zmembrane1} units box 
variable num_feed_waters equal "count(ox,feedzone)"
variable num_feed_na equal "count(na,feedzone)"
variable num_feed_cl equal "count(cl,feedzone)"

thermo_style    custom step temp etotal vol press v_num_feed_waters v_num_feed_na v_num_feed_cl 
restart 2500000 $FILENAME.dynamics.restart

dump    fulldump     all atom 1000 $FILENAME.dynamics.lammpstrj
run     20000000

EOF

cd $OUTPUT
rm -f $FILENAME.out
			done
		done
	done
done
